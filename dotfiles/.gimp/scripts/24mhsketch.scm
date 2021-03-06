;SKETCH
;Kiki

(define (script-fu-mhsketch1 img drawable)
  (let* ((width (car (gimp-image-width img)))
         (height (car (gimp-image-height img)))
	 (layer1 (car (gimp-layer-copy drawable TRUE)))
        )

  (gimp-image-add-layer img layer1 0)
  (plug-in-gauss-iir 1 img layer1 5 TRUE TRUE)
  (gimp-invert layer1)
  (gimp-layer-set-opacity layer1 50)
  )
)

(define (script-fu-mhsketch2 img drawable low high llz)
  (let* ((layer1 (car (gimp-layer-copy drawable TRUE)))
	;2.4         X
	 (llz 0)
        )
  (set! llz (car (gimp-image-merge-visible-layers img 1)))
  (gimp-levels llz 0 100 155 1 0 255)
  (gimp-desaturate llz)
  (gimp-levels llz 0 low high 1 0 255)
  )
)


(define (script-fu-mhsketch img drawable low high)
  (gimp-undo-push-group-start img)

;2.4    
  (let ((llz 0)
       )

  (script-fu-mhsketch1 img drawable)
  (script-fu-mhsketch2 img drawable low high llz)

  (gimp-undo-push-group-end img)
  (gimp-displays-flush)

;2.4    (let)
 )
)

(script-fu-register "script-fu-mhsketch"
		    _"<Image>/Script-Fu/MH/SKETCH..."
		    "sketch"
		    "Kiki"
		    "GIANTS"
		    "2005/1/13"
		    "RGB*"
		    SF-IMAGE	"Image" 0
		    SF-DRAWABLE "Drawable" 0
		    SF-ADJUSTMENT _"low"       '(39 0 255 1 2 0 0)
		    SF-ADJUSTMENT _"high"      '(128 0 255 1 2 0 0)
		    )



;;mhcsketch
;Kiki

(define (script-fu-mhcsketch img drawable md len edg ft)
  (let* (

;;        
	 (width (car (gimp-drawable-width drawable)))
	 (height (car (gimp-drawable-height drawable)))

;;       C   [
	 (mb-layer (car (gimp-layer-new img width height RGB-IMAGE "Background" 100 NORMAL-MODE)))

         (edg (+ edg 39))

;2.4    
	 (l1 0)
	 (l2 0)
	 (la 0)
	 (ll1 0)
	 (ll2 0)
	 (ll 0)
	 (mb-layer2 0)
	 (a 0)
	 (b 0)
	 (s-layer 0)
	 (c1 0)
	 (cc 0)
)
    (gimp-undo-push-group-start img)

    (set! l1 (car (gimp-layer-copy drawable 0)))
    (gimp-image-add-layer img l1 0)

(if (= md 0)
(begin
    (set! l2 (car (gimp-layer-copy drawable 0)))
    (gimp-image-add-layer img l2 0)
    (plug-in-gauss-iir2 1 img l2 5 5)
    (gimp-layer-set-mode l2 6)
    (set! la (car (gimp-image-merge-down img l2 0)))
    (gimp-invert la)
    (gimp-desaturate la)

    (set! ll1 (car (gimp-layer-copy la 0)))
    (gimp-image-add-layer img ll1 0)
    (gimp-layer-set-mode ll1 MULTIPLY-MODE)
    (set! ll2 (car (gimp-layer-copy la 0)))
    (gimp-image-add-layer img ll2 0)
    (gimp-layer-set-mode ll2 MULTIPLY-MODE)
    (gimp-layer-set-visible drawable 0)
    (set! ll (car (gimp-image-merge-visible-layers img 1)))
    (gimp-levels ll 0 0 220 0.5 0 255)
    (gimp-layer-set-visible drawable 1)
))
(if (> md 0)
(begin
    (gimp-layer-set-visible drawable 0)
    (script-fu-mhsketch img l1 39 edg)
    (set! ll (car (gimp-image-merge-visible-layers img 1)))	;2.4    
    (gimp-layer-set-visible drawable 1)
))

    (gimp-layer-set-mode ll MULTIPLY-MODE)

    (gimp-image-add-layer img mb-layer 1)
    (gimp-selection-all img)
    (gimp-edit-clear mb-layer)
    (gimp-selection-none img)
    (plug-in-noisify 1 img mb-layer 0 1 1 1 0)
    (set! mb-layer2 (car (gimp-layer-copy mb-layer 0)))
    (gimp-image-add-layer img mb-layer2 1)
    (if (< md 2)
    (begin
      (set! a 45)
      (set! b 135)
    ))
    (if (= md 2)
    (begin
      (set! a 10)
      (set! b 170)
    ))
    (if (= md 3)
    (begin
      (set! a 45)
      (set! b 135)
    ))
    (plug-in-mblur 1 img mb-layer 0 len a 0 0)
    (plug-in-mblur 1 img mb-layer2 0 len b 0 0)
    (gimp-layer-set-mode mb-layer2 MULTIPLY-MODE)
    (set! s-layer (car (gimp-image-merge-down img mb-layer2 0)))
    (gimp-layer-set-mode s-layer SCREEN-MODE)

    (if (= md 3)
    (begin
      (set! c1 (car (gimp-layer-copy drawable 0)))
      (set! cc (car (gimp-image-merge-visible-layers img 1)))
      (gimp-image-add-layer img c1 1)
      (gimp-layer-set-mode cc 14)
    ))

    (if (= ft TRUE) (gimp-image-merge-visible-layers img 1))

    (gimp-undo-push-group-end img)
    (gimp-displays-flush)
))

(script-fu-register "script-fu-mhcsketch"
		    "<Image>/Script-Fu/MH/sketchcolor"
		    "csketch"
		    "Kiki"
		    "Giants"
		    "2005/5"
		    "RGB*"
		    SF-IMAGE		"Image"		0
		    SF-DRAWABLE		"Drawable"	0
                    SF-OPTION		"mode"		'(_"0" _"1" _"2" _"3(vivid)")
		    SF-ADJUSTMENT	"length"	'(10 2 80 1 2 0 0)
		    SF-ADJUSTMENT	"edge(only mode1)"	'(80 1 120 1 2 0 0)
                    SF-TOGGLE		"Flatten Image"	TRUE
)




;suisai
;Kiki

(define (script-fu-mhsuisai img drawable han edg ns ft)
  (let* ((width (car (gimp-image-width img)))
         (height (car (gimp-image-height img)))
         (edg (+ edg 39))
	 ;2.4    
	 (layer1 0)
	 (ll 0)
	 (layer2 0)
	 (ll2 0)
        )
  (gimp-undo-push-group-start img)

  (set! layer1 (car (gimp-layer-copy drawable 0)))
  (gimp-image-add-layer img layer1 0)
  (gimp-layer-set-visible drawable 0)

  (script-fu-mhsketch img layer1 39 edg)
  (set! ll (car (gimp-image-merge-visible-layers img 1)))	;2.4    
  (gimp-layer-set-mode ll OVERLAY-MODE)

  (plug-in-despeckle 1 img drawable han 0 -1 255)
  (plug-in-oilify 1 img drawable 5 1)
  (set! layer2 (car (gimp-layer-copy drawable 0)))
  (gimp-image-add-layer img layer2 1)

  (gimp-layer-set-visible ll 0)
  (gimp-layer-set-visible layer2 1)
  (script-fu-mhsketch1 img layer2)
  (set! ll2 (car (gimp-image-merge-visible-layers img 1)))
  (gimp-levels ll2 0 100 155 1 0 255)
  (gimp-desaturate ll2)
  (gimp-levels ll2 0 39 128 1 0 255)
  (gimp-layer-set-mode ll2 MULTIPLY-MODE)
  (plug-in-noisify 1 img drawable 0 ns ns ns 0)

  (gimp-layer-set-visible drawable 1)
  (gimp-layer-set-visible ll 1)

  (if (= ft TRUE) (gimp-image-merge-visible-layers img 0))

  (gimp-undo-push-group-end img)
  (gimp-displays-flush)
  )
)

(script-fu-register "script-fu-mhsuisai "
		    _"<Image>/Script-Fu/MH/suisai..."
		    "suisai "
		    "Kiki"
		    "GIANTS"
		    "2005/5"
		    "RGB*"
		    SF-IMAGE	"Image" 0
		    SF-DRAWABLE "Drawable" 0
		    SF-ADJUSTMENT _"radius"	'(3 1 10 1 2 0 0)
		    SF-ADJUSTMENT _"edge"	'(80 1 120 1 2 0 0)
		    SF-ADJUSTMENT  "noise"	'(0.08 0.01 0.1 0.01 0.02 2 0)
                    SF-TOGGLE      "Flatten Image"  TRUE
		    )

