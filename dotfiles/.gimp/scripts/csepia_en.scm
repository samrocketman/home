; cSepia v0.2 by Kacper Gunia (Cakper)
; This is a simple script for GIMP which allowing us do add a sepia effect to active layer.
; Script was written with using this tutorial: http://maniooo.pl/sepiatoning.php and working with GIMP 2.4 and erlier.
; Contact with autor: cakper@gmail.com - email; cakper@jabber.org - Jabber
; Author is administrator of Polish GIMP Users Forum - www.gimpuj.info Come Us!
; If have you any problems with script please visit script theread on forum: http://www.gimpuj.info/scriptfus-plugins/csepia-t8615.0.html
; Script is released under Creative Commons Attribution-Noncommercial-Share Alike 3.0 Unported license.

(define (cSepia img drawable csepiamode halftone)

	(let* 
		(
		
		 (theLayer
			(car 
				(gimp-layer-new   
				img
				 (car (gimp-image-width img))
				(car (gimp-image-height img))
				0
				"Sepia" 
				100 
				13)
			)
		)
		
		(theMask 
			(car 
				(gimp-layer-create-mask 
				theLayer 
				0)
			)
		)
		
		
		
		(oldfg (car (gimp-context-get-foreground)))
		
		(csepiamode
      (cond
        ((= csepiamode 0) '(162 128 101))
        ((= csepiamode 1) '(162 138 101))
      )
    )

		
		)
		
	(gimp-image-undo-group-start img)	
	(gimp-image-add-layer img theLayer -1)
	(gimp-layer-add-alpha theLayer)
	(gimp-context-set-foreground csepiamode)
	(gimp-drawable-fill theLayer 0)
	(gimp-desaturate drawable)
	(gimp-context-set-foreground oldfg)
	
	(if (= halftone TRUE)
	
		(begin
			(gimp-edit-copy drawable)
			(gimp-layer-add-mask theLayer theMask)
			(gimp-floating-sel-anchor (car (gimp-edit-paste theMask 0)))   
			(gimp-curves-spline theMask 0 6 #(0 0 127 200 255 0))
			
		)
	)
	(gimp-image-merge-down img theLayer 2)
	(gimp-image-undo-group-end img)
	(gimp-displays-flush)
	)

)

(script-fu-register "cSepia"
	_"<Image>/Filters/Artistic/cSepia"
	"Add a sepia effect to active Layer"
	"Kacper Gunia (email: cakper@gmail.com | jabber: cakper@jabber.org)"
	"Creative Commons Attribution-Noncommercial-Share Alike 3.0 Unported"
	"October 2007"
	"*"
	SF-IMAGE	"Image"		0
	SF-DRAWABLE	"Drawable"	0
	SF-OPTION     "Sepia base color:"            '("Standard" "Clearer")
	 SF-TOGGLE		    _"Halftones expostion"	  FALSE
	 )
