;; (load "/home/dfish/.julia/dev/ACTRTutorial/actr6/load-act-r-6.lisp")
;; (load "/home/dfish/.julia/dev/FundamentalToolsACTR/models/Semantic/temp.lisp")
;; (generate-recovery-data 100 100 "/home/dfish/.julia/dev/ACTRTutorial/Tutorial_Models/Markov Chain Models/Semantic MP/recovery_data")

(clear-all)

(defvar *response*)
(defvar *response-time*)
(defvar *rt* 0.0)

(defun run-semantic-model (term1 term2)
  (let ((window (open-exp-window "Semantic Model"
                                 :visible nil
                                 :width 600
                                 :height 300))
        (x 25))

    (reset)
    (install-device window)

   (dolist (text (list term1  term2))
     (add-text-to-exp-window :text text :x x :y 150 :width 75)
     (incf x 75))

    (setf *response* nil)
    (setf *response-time* nil)

    (proc-display)

    (run 30)
    (if (string-equal *response* "j")
        (setf present "yes")
        (setf present "no"))

    (if (null *response*)
        nil
      present)))

(defmethod rpm-window-key-event-handler ((win rpm-window) key)
  (setf *response-time* (get-time t))

(setf *response* (string key)))

(defun generate-data (n-reps)
    (let ((stimuli (list)) (results (list)))
    (setf stimuli (list '("canary" "fish" "yes")))
    (dolist (stimulus stimuli)
        (push (run-n-times n-reps (nth 0 stimulus)
            (nth 1 stimulus) (nth 2 stimulus)) results)
    )
    results))

(defun generate-recovery-data (n-parms n-reps path)
  (sgp :seed (584001 98))
  (let ((responses (list)) (file-name) (all-parms (list (list "rt"))) (parms (list)))
    (dotimes (i n-parms)
      (setf responses (list))
      (setf *rt* (sample -1.0 1.0))
      (setf parms (list *rt*))
      (setf all-parms (append all-parms (list parms)))
      (setf responses (append responses (generate-data n-reps)))
      (setf file-name (concatenate 'string path "/data_set_" (write-to-string i) "_.csv"))
      (write-to-file responses file-name))
      (setf file-name (concatenate 'string path "/true_parms.csv"))
      (write-to-file all-parms file-name)))

(defun run-n-times (n object category answer)
   (let ((num-yes 0) (response))
   (dotimes (i n)
      (setf response (run-semantic-model object category))
      (if (equal response "yes")
        (incf num-yes)))
      (list object category answer n num-yes)))

(defun sample (lb ub)
  (let ((val))
    (setf val (+ (act-r-random (- ub lb)) lb))
  ))

(defun penalty-fct (chunk request)
  (let ((chunk-type) (slot-value) (val) (mp))
      (setf chunk-type (chunk-spec-chunk-type request))
      (setf mp (first (sgp :mp)))
      (cond ((eq chunk-type 'meaning)
              (setf val (compute-penalty chunk request (* mp 20))))
          ((neq chunk-type 'meaning)
              (setf val (compute-penalty chunk request mp))))

      val))

(defun compute-penalty (chunk request scale)
  (let ((penalty 0) (slot-value))
  (dolist (k (chunk-spec-slot-spec request))
      (setf slot-value (fast-chunk-slot-value-fct chunk (second k)))
      (cond ((eq slot-value nil)
          (incf penalty scale))
      ((neq slot-value nil)
          (when (not (chunk-slot-equal slot-value (third k)))
              (incf penalty scale)))))
      (* -1 penalty)))

(defun write-to-file (lst FileName)
(with-open-file (file FileName
                      :direction :output
                      :if-exists :supersede
                      :if-does-not-exist :create)
  (loop for row in lst
    do (loop for n in row
         do (princ n file)
         (princ "," file))
         (fresh-line file))))

(defun read-csv (filename delim-char)
  "Reads the csv to a nested list, where each sublist represents a line."
(with-open-file (input filename)
  (loop :for line := (read-line input nil) :while line
        :collect (read-from-string
                  (substitute #\SPACE delim-char
                              (format nil "(~a)~%" line))))))

(define-model semantic

(sgp-fct (list :esc t :v t :act t :mas 1.6 :ga 1.0 :imaginal-activation 1.0))

(chunk-type info a b c)
(chunk-type is-member object category judgment)
(chunk-type something a b)

(add-dm

 (c1 isa info a a b b c c)
 (c2 isa info a a b b c a)  
 (goal1 ISA is-member))

 (P a
     =goal>
        ISA         is-member
    ?retrieval>
        state free
    ?imaginal>
        state       free
    ==>
    +imaginal>
        ISA something
        a a
        b b
 )

  (P b
     =goal>
        ISA      is-member
    =imaginal>
        ISA something
        a a
        b b
    ?retrieval>
        state free
    ==>
    +retrieval>
        ISA info
    =imaginal>
 )

   (P c
     =goal>
        ISA      is-member
    =retrieval>
        ISA info
        a a
        b b
    ==>
      -goal>
 )
(goal-focus goal1))

