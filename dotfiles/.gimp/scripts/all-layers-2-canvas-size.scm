;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;; Layers to Image Size 07/05 
;; by noclayto <www.gimptalk.com> 
;; Resizes All Layers To The Canvas Size 

;; This script is mainly for learning. Use at your own risk. 

(define (script-fu-Layers-to-Image-Size img drawable) 
	(let* ( 
		(num (car (gimp-image-get-layers img))) 
		(layers (cadr (gimp-image-get-layers img))) 
		) 

		(gimp-image-undo-group-start img) 

		(while (>= num 1) 
			(gimp-layer-resize-to-image-size (aref layers (- num 1))) 
			(set! num (- num 1))
		) 

		(gimp-image-undo-group-end img) 
		(gimp-displays-flush)
	)
) 

(script-fu-register "script-fu-Layers-to-Image-Size" 
_"<Image>/Layer/Layer(s) to Image Size" 
"Resizes All Layers To The Canvas Size" 
"noclayto" 
"noclayto" 
"July 2005" 
"" 
SF-IMAGE "Image" 0 
SF-DRAWABLE "Drawable" 0) 
