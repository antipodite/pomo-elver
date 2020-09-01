(defsystem "pomo-elver"
  :version "0.1.0"
  :author "Isaac Stead"
  :license "GPL"
  :depends-on ("postmodern"
               "ironclad"
               "alexandria"
               "local-time")
  :components ((:module "src"
                :components
                ((:file "migrations"))))
  :description ""
  :in-order-to ((test-op (test-op "pomo-elver/tests"))))

(defsystem "pomo-elver/tests"
  :author "Isaac Stead"
  :license "GPL"
  :depends-on ("pomo-elver"
               "rove")
  :components ((:module "tests"
                :components
                ((:file "main"))))
  :description "Test system for pomo-elver"
  :perform (test-op (op c) (symbol-call :rove :run c)))
