;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Time Change
;;  by noclayto <www.gimptalk.com>
;;  Will change the time of all layers eg Frame 1 (100ms) (combine) ... 

;;  This script is mainly for learning. Use at your own risk.
;;  ALL RIGHTS RESERVED
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (script-fu-time-change img drawable req-mode time)
  ;;  Frame 14 (200ms) (combine)
  (let* ( 
	 (num (car (gimp-image-get-layers img))) 
	 (layers (cadr (gimp-image-get-layers img)))
	 (str)
	 (str-temp)
	 (l-num (+ num 1))
	 (str-num)
	 (mode)
	 ) 
	 
	 (if (= req-mode 0)
         (begin 
         	(set! mode "combine")
         )
         (begin
          	(set! mode "replace")
         )
     )
    
    ;;(aref layers (- num 1)))
    (gimp-context-push)
    (gimp-image-undo-group-start img)
    
    (set! str (string-append  "(" (number->string time 10) "ms) (" mode ")" ))
    
    (while (>= num 1)
	   (set! str-num  (number->string (- l-num num) 10))
	   (set! str-temp (string-append  "Frame " str-num " " str ))
	   (gimp-drawable-set-name (aref layers (- num 1)) str-temp)
	   (set! num (- num 1)))
        
    (gimp-image-undo-group-end img)
    (gimp-context-pop)
    (gimp-displays-flush)))

(script-fu-register "script-fu-time-change"
		    ;_"<Image>/Script-Fu/Animators/Time Change"
		    "<Image>/Filters/Animation/Time Change"
		    ""
		    "noclayto"
		    "noclayto"
		    "July 2005"
		    ""
            SF-IMAGE       "Image"    0
		    SF-DRAWABLE    "Drawable" 0
		    ;SF-STRING     _"Mode"      "combine"
		    SF-OPTION "Mode:" '("(combine)" "(replace)")
		    SF-ADJUSTMENT _"Time(ms)"  '(150 10 6000 1 10 0 1)
		    )




