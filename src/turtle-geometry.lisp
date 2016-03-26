;;;; turtle-geometry.lisp

(in-package #:turtle-geometry)

;;; "turtle-geometry" goes here. Hacks and glory await!

(defun update-program-matrices ()
  (set-program-matrices (get-program "turtle"))
  (set-program-matrices (get-program "line")))

(defun init-turtle-geometry ()
  (let ((line-program (make-program
                       (file-in-dir *shader-directory* "line.v.glsl")
                       (file-in-dir *shader-directory* "line.f.glsl")))
        (turtle-program (make-program
                         (file-in-dir *shader-directory* "basic.v.glsl")
                         (file-in-dir *shader-directory* "basic.f.glsl"))))

    (load-program "turtle" turtle-program)
    (load-program "line" line-program)

    (set-program-matrices turtle-program)
    (set-program-matrices line-program)

    (setf *turtle* (make-turtle)
          *turtle-drawer* (make-turtle-drawer turtle-program)
          *line-drawer* (make-line-drawer line-program)
          *camera* (make-init-camera))))

(defun make-init-camera ()
  (make-instance 'camera :position (vec3f 0.0 0.0 100.0)
                         :movement-speed 50.0
                         :mouse-sensitivity 0.1))

(defun handle-camera-input ()
  (when (key-pressed-p :left-control)
    (when *cursor-callback-p*
      (let ((x-offset (cfloat (- *cursor-x* *last-x*)))
            (y-offset (cfloat (- *last-y* *cursor-y*))))
        (process-rotation-movement *camera* x-offset y-offset)))

    (when *scroll-callback-p*
      (process-scroll-movement *camera* (cfloat *scroll-y*))) 

    (when (key-pressed-p :w)
      (process-direction-movement *camera* +forward+ *dt*))
    (when (key-pressed-p :s)
      (process-direction-movement *camera* +backward+ *dt*))
    (when (key-pressed-p :a)
      (process-direction-movement *camera* +left+ *dt*))
    (when (key-pressed-p :d)
      (process-direction-movement *camera* +right+ *dt*)))

  (update-program-matrices)

  (setf *last-x* *cursor-x*
        *last-y* *cursor-y*)
  (setf *cursor-callback-p* nil
        *scroll-callback-p* nil))

(defevent clear ()
  ;; reset turtle
  ;; reset line-drawer
  ;; reset camera
  (setf *turtle* (-> *turtle*
                     (with :position (vec3f 0.0 0.0 0.0))
                     (with :rotation (vec3f 0.0 0.0 0.0)))
        *camera* (make-init-camera)
        *line-drawer* (make-line-drawer (get-program "line"))))

(defevent pen-toggle ())

(defevent pen-down ())
(defevent pen-up ())

(defevent color (vec)
  (includef *turtle* :color (vec4f vec)))

(defevent forward (distance)
  (let ((new-pos (vec3f (kit.glm:matrix*vec4
                         (kit.glm:matrix*
                          (kit.glm:translate (@ *turtle* :position))
                          (kit.glm:rotate (@ *turtle* :rotation)))
                         (vec4f 0.0 (cfloat distance) 0.0 1.0)))))

    ;; move turtle's position
    (includef *turtle* :position new-pos)

    ;; add new data to drawer if pen-down
    (when (@ *turtle* :pen-down-p)
      (incf (num-vertices *line-drawer*))
      (add-turtle-data (draw-array *line-drawer*)))))

(defevent rotate-turtle (vec)
  (includef *turtle* :rotation (vec3f+ (@ *turtle* :rotation) vec)))

(defun left (radians)
  ;; rotate turtle around z-axis
  (rotate-turtle (vec3f 0.0 0.0 (cfloat radians))))

(defun right (radians)
  ;; same as right in opposite direction
  (left (- radians)))

(defun square (side-length)
  (dotimes (x 4)
    (forward side-length)
    (right (/ pi 2))))

(defun circle (radius)
  (let* ((sides 30)
         (circumference (* 2 radius pi))
         (side-length (/ circumference sides)))
    (dotimes (x sides)
      (forward side-length)
      (right (/ (* 2 pi) sides)))))

(defun squiggle (l)
  (forward l)
  (right (/ pi 2))
  (forward l)
  (right (/ pi 2))
  (forward (* 0.5 l))
  (right (/ pi 2))
  (forward (* 0.5 l))
  ;; (right (/ pi 2))
  ;; (forward l)
  ;; (right (/ pi 2))
  (forward (* 0.25 l))
  (right (/ pi 2))
  (forward (* 0.25 l))
  (right (/ pi 2))
  (forward (* 0.5 l)))

(defun thing (fn &rest args)
  (dotimes (x 100)
    (apply fn args)
    (right (/ pi 10))
    (forward 2)))

;; (defevent pattern (fn)
;;     (dotime))
