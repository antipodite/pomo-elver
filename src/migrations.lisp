;;;;
;;;; Basic migration support for a Postgresql database.
;;;; (c) Isaac Stead, August 2020
;;;;
;;;; Migrations are defined using DEFMIGRATION. They consist of a version number,
;;;; comments, and a list of SQL queries that define the migration. They are stored
;;;; in a database table

(defpackage weft.migrations
  (:use :common-lisp
        :postmodern
        :ironclad)
  (:import-from :alexandria
                :hash-table-values
                :with-gensyms)
  (:export :defmigration))

(in-package :weft.migrations)

(defun object->md5 (object)
  "Compute MD5 hash of given object and return it.
This is used here to provide a unique ID for migrations by hashing the S-SQL
query or queries that define the migration"
  (digest-sequence :md5 (ascii-string-to-byte-array (write-to-string object))))

(defclass migration ()
  ((id
    :col-type integer :col-identity t :reader migration-id)
   (queries
    :col-type string :type list :initarg :queries :reader migration-queries)
   (version
    :col-type integer :unique t :initarg :version :reader migration-version)
   (timestamp
    :col-type timestamp :initform nil :reader migration-timestamp)
   (comment
     :col-type (or string db-null) :initarg :comment :reader migration-comment))
  (:metaclass dao-class)
  (:keys id)
  (:table-name migrations)
  (:documentation "Class to support basic migrations."))

(eval-when (:compile-toplevel :load-toplevel)
  (defparameter *migrations* (make-hash-table :test #'equalp)))

(defun make-migration (&key version queries comment)
  "Define a new migration."
  (let ((new-migration (make-instance 'migration
                                      :version version
                                      :queries queries
                                      :comment comment)))
    new-migration))

(defmacro defmigration (migration-spec &body queries)
  "Define a migration. The migrations are stored in the migration table
at compile time and then are available to be applied with APPLY-ALL-MIGRATIONS"
  ;; Check the syntax of the migration spec
  (if (and (eq (type-of migration-spec) 'cons)
           (eq (first migration-spec) :version)
           (eq (third migration-spec) :comment))
      (with-gensyms (new-migration)
        `(let ((,new-migration (make-migration :version (second ',migration-spec)
                                               :queries (list ,@queries)
                                               :comment (fourth ',migration-spec))))
           (setf (gethash (migration-version ,new-migration) *migrations*) ,new-migration)))
      ;; Else
      (error "The migration binding spec ~a is malformed" migration-spec)))

(defmethod migration-store ((migration migration))
  (query (:insert-into 'migrations :set
                       'version (migration-version migration)
                       'queries (write-to-string (migration-queries migration))
                       'timestamp (local-time:now) 'comment (migration-comment migration))))

(defgeneric apply-migration (migration &key verbose)
  (:documentation "Update the database to reflect the migration. Should
perform necessary checks first, like the current db version, whether 
migration table exists, etc"))

(defmethod apply-migration ((migration migration) &key (verbose t))
  (let* ((current-version (current-version))
         (new-version     (migration-version migration))
         (version-diff    (- new-version current-version)))
    ;; Error checking before applying migration
    (cond ((not (= 1 version-diff))
           (error "Migration version ~a is out of sync with database version ~a"
                  new-version
                  current-version))
          ((select-dao 'migration (:= 'version (migration-version migration)))
           (when verbose
             (format t "Migration to version ~a has already been applied"
                     new-version))
           nil)      
          (:else (with-transaction ()
                   (mapc (lambda (q) 
                           (query (ctypecase q
                                    (cons (sql-compile q))
                                    (simple-array q))))
                         (migration-queries migration)))
                 (migration-store migration)
                 (when verbose
                   (format t "Successfully applied migration version ~a->~a: ~a~&"
                           current-version new-version (migration-comment migration)))))
    t))

(defun apply-all-migrations (&key (verbose t))
  "Apply all migrations that were found at compile time that define a higher
version that the current version."
  (let ((current-version (current-version)))
    (mapc (lambda (m) (apply-migration m :verbose verbose))
          (sort (remove-if-not (lambda (m) (> (migration-version m) current-version))
                               (hash-table-values *migrations*))
                #'<
                :key #'migration-version))))

(defun initial-migration (&optional (version 0))
  "Create the migration table. This is considered version 0 of the database
by default, but the version can optionally be specified as something else.
This allows existing databases to be migrated"
    (let ((first-migration (make-migration :version version
                                           :queries (dao-table-definition 'migration)
                                           :comment "Initial migration. Created migration table")))
      (with-transaction ()
        (query (migration-queries first-migration))
        (migration-store first-migration))))

(defun current-version ()
  (let ((version (query (:order-by (:select 'version :from 'migrations)
                                   (:desc 'version))
                        :single)))
    (if version
        version
        (error "Migrations table has not been set up on database. ~ 
                Did you run INITIAL-MIGRATION?"))))

(defun show-migrations (&key (migration-table *migrations*))
  nil)
