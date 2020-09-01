(defpackage pomo-elver/tests/main
  (:use :cl
        :pomo-elver
        :rove))
(in-package :pomo-elver/tests/main)

;; NOTE: To run this test file, execute `(asdf:test-system :pomo-elver)' in your Lisp.

(deftest test-target-1
  (testing "should (= 1 1) to be true"
    (ok (= 1 1))))
