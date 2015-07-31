
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Fade Animator
;;  COPYRIGHT by noclayto <noclayto.deviantart.com>
;;  Will fade a layers into each other.
;;  All rights reserved
;;
;; This script is mainly for learning. Use at your own risk.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (script-fu-fade-animator img drawable step)
  
  (let* (
	 (counter step) 
	 (new-layer)
	 (fade-to-layer)
	 (num-layers  (car  (gimp-image-get-layers img))) 
	 (num num-layers)
	 (num-temp (- num 1))
	 (layers (cadr (gimp-image-get-layers img)))
	 (new-img (car (gimp-image-new 
			(car (gimp-image-width img))
			(car (gimp-image-height img))
			RGB)))
	 
	 
	 ) 
    
    (gimp-context-push)
    (gimp-image-undo-group-start new-img)

    
    (while (> num 0)
	   (set! new-layer (car (gimp-layer-new-from-drawable (aref layers (- num 1)) new-img)))
	   (gimp-image-add-layer new-img new-layer -1)
		
	   (set! new-layer (car (gimp-layer-new-from-drawable (aref layers (- num 1)) new-img)))
	   (gimp-image-add-layer new-img new-layer -1)
		       
	   (if (< num-temp 1) (set! num-temp num-layers ))
	  
 ;;add layer above.  then add level adjusted layer.  then merge down
	   (while (< counter 255)
		  (set! new-layer (car (gimp-layer-new-from-drawable (aref layers (- num-temp 1)) new-img)))
		  (gimp-image-add-layer new-img new-layer -1)
	
		  (set! new-layer (car (gimp-layer-new-from-drawable (aref layers (- num 1)) new-img)))
		  (gimp-image-add-layer new-img new-layer -1)
		  
		  (gimp-levels new-layer 4 0 255 1 0 (- 255 counter))
		  (gimp-image-merge-down new-img new-layer 0)
		  (set! counter (+ counter step))
		  )
	   (set! counter step)
	   (set! num (- num 1))
	   (set! num-temp (- num-temp 1))
	   )

    
    (gimp-image-undo-group-end new-img)
    (gimp-display-new new-img)
    (gimp-context-pop)
    (gimp-displays-flush)))

(script-fu-register "script-fu-fade-animator"
		    _"<Image>/Script-Fu/Animators/Fade..."
		    ""
		    "noclayto"
		    "noclayto"
		    "July 2005"
		    "RBG"
                    SF-IMAGE       "Image"    0
		    SF-DRAWABLE    "Drawable" 0
		    SF-ADJUSTMENT _"Iterations = 255 / #"  '(51 1 255 1 10 0 1)
		    )




