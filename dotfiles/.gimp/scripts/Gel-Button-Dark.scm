;Author: Mike Pippin
;Version: 1.0
;Homepage: Split-visionz.net
;License: Released under the GPL included in the file with the scripts.

(define (script-fu-sv-gel-buttond mywidth myheight bgcolor)

(let* (
	(image (car (gimp-image-new mywidth myheight RGB)))
	(bg-layer (car (gimp-layer-new image mywidth myheight RGBA-IMAGE "bgLayer" 100 NORMAL-MODE)))
	(grad-layer (car (gimp-layer-new image mywidth myheight RGBA-IMAGE "gradLayer" 100 NORMAL-MODE)))
	(hl-layer (car (gimp-layer-new image mywidth myheight RGBA-IMAGE "hlLayer" 100 NORMAL-MODE)))	
	(line-layer (car (gimp-layer-new image mywidth myheight RGBA-IMAGE "lineLayer" 100 NORMAL-MODE)))	
	(gloss-layer (car (gimp-layer-new image mywidth myheight RGBA-IMAGE "glossLayer" 100 NORMAL-MODE)))
	(halfheight (/ myheight 2))
	(quarterheight (/ myheight 4))
	(points (cons-array 4 'double))
	(oldforeground(gimp-context-get-foreground))
	(oldbackground(gimp-context-get-background))
	(lineblurradius(* myheight 0.4))
	(sideline (* myheight 0.80))
	(lpoints (cons-array 4 'double))	
	(rpoints (cons-array 4 'double))
)
(aset points 0 -1)
(aset points 1 (- myheight 1))
(aset points 2 mywidth)
(aset points 3 (- myheight 1))

(aset lpoints 0 1)
(aset lpoints 1 (- myheight 1))
(aset lpoints 2 1)
(aset lpoints 3 (- myheight sideline))

(aset rpoints 0 (- mywidth 1))
(aset rpoints 1 (- myheight 1))
(aset rpoints 2 (- mywidth 1))
(aset rpoints 3 (- (- myheight sideline) 1))

(gimp-context-set-foreground bgcolor)
(gimp-context-set-background '(0 0 0))

(gimp-drawable-fill bg-layer 0)
(gimp-image-add-layer image bg-layer 0)

(gimp-image-add-layer image grad-layer 0)
(gimp-edit-clear grad-layer)
(gimp-image-add-layer image hl-layer 0)
(gimp-edit-clear hl-layer)
(gimp-image-add-layer image line-layer 0)
(gimp-edit-clear line-layer)
(gimp-image-add-layer image gloss-layer 0)
(gimp-edit-clear gloss-layer)

(gimp-edit-blend grad-layer 0  0 0 100 0 0 FALSE FALSE 0 0 TRUE 0 halfheight 0 myheight)
(gimp-layer-set-opacity grad-layer 25)

(gimp-brushes-set-brush "Circle (03)")

(if(<= myheight 125)
	(gimp-brushes-set-brush "Circle (09)")
	)
(if(<= myheight 100)
	(gimp-brushes-set-brush "Circle (07)")
	)
(if(<= myheight 75)
	(gimp-brushes-set-brush "Circle (05)")
	)
(if(<= myheight 50)
	(gimp-brushes-set-brush "Circle (01)")
	)

(gimp-context-set-foreground '(0 0 0))

(gimp-paintbrush-default hl-layer 4 points)
(gimp-paintbrush-default line-layer 4 points)

(gimp-paintbrush-default line-layer 4 rpoints)

(gimp-paintbrush-default line-layer 4 lpoints)

(plug-in-gauss-rle 1 image hl-layer lineblurradius 1 1)

(gimp-context-set-foreground '(255 255 255))

(gimp-rect-select image -1 -1 (+ 1 mywidth) halfheight 0 FALSE 0)

(gimp-image-set-active-layer image gloss-layer)

(gimp-edit-blend gloss-layer 2 0 0 75 0 0 FALSE FALSE 0 0 TRUE 0 (- 0 quarterheight) 0 (+ halfheight quarterheight))
(gimp-selection-none image)

(gimp-image-set-active-layer image line-layer)

(gimp-rect-select image -1 -1 (+ 3 mywidth) (* myheight 0.40) 0 TRUE lineblurradius )

(gimp-edit-cut line-layer)
(gimp-layer-set-opacity line-layer 85)

(gimp-display-new image)

(gimp-image-clean-all image)

image
)
)


(script-fu-register "script-fu-sv-gel-buttond"
		    _"<Toolbox>/Xtns/SV-Scripts/GelBar-Dark"
		    "Creates a Web2.0 style gel button"
		    "Mike Pippin"
		    "copyright 2007-8, Mike Pippin"
		    "Dec 2007"
		    ""
		    SF-ADJUSTMENT _"Width" '(200 1 2000 1 10 0 1)
		    SF-ADJUSTMENT _"Height" '(50 1 2000 1 10 0 1)
			SF-COLOR      "Background Color" '(22 22 125)
			
			)