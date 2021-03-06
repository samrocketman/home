; The GIMP -- an image manipulation program
; Copyright (C) 1995 Spencer Kimball and Peter Mattis
; 
; www.gimp.org web big header
; Copyright (c) 1997 Jens Lautenbacher
; jens@gimp.org
;
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; 
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

(define (script-fu-old-stone text font
			       font-size fg-color bg-color age
			       crop rm-bg index num-colors)
  (let* ((img (car (gimp-image-new 256 256 RGB)))
	 (text-layer (car (gimp-text-fontname img -1 0 0
				              text 20 TRUE font-size PIXELS font)))
	 (width (car (gimp-drawable-width text-layer)))
	 (height (car (gimp-drawable-height text-layer)))
	 (bg-layer (car (gimp-layer-new img width
					height RGB-IMAGE
					"Background" 100 NORMAL-MODE)))
	 (fg-layer (car (gimp-layer-new img width
					height RGB-IMAGE
					"fg" 100 NORMAL-MODE)))
	 (map-layer (car (gimp-layer-new img width
					height RGB-IMAGE
					"map" 100 NORMAL-MODE)))
	 (plasma-layer (car (gimp-layer-new img width
					height RGB-IMAGE
					"plasma" 100 NORMAL-MODE)))
    
	 (old-fg (car (gimp-context-get-foreground)))
	 (old-bg (car (gimp-context-get-background)))
	 (mask 0) )

    (gimp-image-undo-disable img)

    ;; prepare the layers
    (gimp-image-resize img width height 0 0)
    (gimp-image-add-layer img bg-layer 1)
    (gimp-context-set-background bg-color)
    (gimp-edit-fill bg-layer BACKGROUND-FILL)
    
    (gimp-layer-set-preserve-trans text-layer TRUE)
    (gimp-context-set-background '(0 0 0))
    (gimp-edit-fill text-layer BACKGROUND-FILL)
    (gimp-layer-set-preserve-trans text-layer FALSE)

    (gimp-image-add-layer img map-layer 1)
    (gimp-image-add-layer img plasma-layer 1)
    (gimp-image-add-layer img fg-layer 1)

    (gimp-layer-add-alpha map-layer)
    (gimp-layer-add-alpha plasma-layer)
    (gimp-layer-add-alpha fg-layer)
    (gimp-image-lower-layer img text-layer)
    (gimp-drawable-set-visible plasma-layer FALSE)
    (gimp-drawable-set-visible map-layer FALSE)
    
    (gimp-context-set-background '(255 255 255))
    (gimp-edit-fill map-layer BACKGROUND-FILL)

    (gimp-context-set-background fg-color)
    (gimp-edit-fill fg-layer BACKGROUND-FILL)

    ;;start with plasma
    (plug-in-plasma 1 img plasma-layer 1 1.5)
    (gimp-desaturate plasma-layer)
    (plug-in-c-astretch 1 img plasma-layer)

    ;; to generate the "stoney" texture...
    (plug-in-blur 1 img plasma-layer)
    (plug-in-oilify 1 img plasma-layer 4 0)
    ;; ..which is used to generate the final map
    (plug-in-bump-map 1 img map-layer plasma-layer 135 45 5 0 0 0 0
		      TRUE FALSE 2)

    ;; now preparing the text
    (plug-in-spread 1 img text-layer age age)
;;    (plug-in-gauss-iir 1 img text-layer 5 TRUE TRUE)
    (plug-in-oilify 1 img text-layer age 0)
    (plug-in-gauss-iir 1 img text-layer (/ font-size 17.) TRUE TRUE)

    (plug-in-bump-map 1 img fg-layer text-layer 135 45 5 0 0 255 0
		     TRUE TRUE 0)

    (set! mask (car (gimp-layer-create-mask fg-layer 1)))
    (gimp-layer-add-mask fg-layer mask)
    (gimp-selection-layer-alpha text-layer)
    (gimp-edit-fill mask WHITE-FILL)
    (gimp-selection-none img)
    (gimp-levels mask 0 0 100 0.35 0 255)

    (gimp-drawable-offset text-layer TRUE 1 5 5)
    (gimp-layer-set-opacity text-layer 50)

    (plug-in-bump-map 1 img fg-layer map-layer  135 45 age 0 0 0 0 TRUE FALSE 2)

    (if (or (= rm-bg TRUE) (= crop TRUE) (= index TRUE))
	(begin
	  (gimp-drawable-set-visible bg-layer 0)
	  (set! text-layer (car (gimp-image-merge-visible-layers img 1)))
	  (gimp-drawable-set-visible bg-layer 1)
	  (gimp-image-remove-layer img map-layer)
	  (gimp-image-remove-layer img plasma-layer)))

    (if (= rm-bg TRUE)
	(begin   
	  (gimp-layer-add-alpha bg-layer)
	  (gimp-edit-clear bg-layer)))

    (if (= crop TRUE)
	(begin
	  (plug-in-autocrop 1 img text-layer)
      (if (= rm-bg TRUE)
          (gimp-image-merge-visible-layers img 1)
          (gimp-image-flatten img))))

    (if (= index TRUE)
	(begin
      (if (= rm-bg TRUE)
          (gimp-image-merge-visible-layers img 1)
          (gimp-image-flatten img))
	  (gimp-image-convert-indexed img FS-DITHER MAKE-PALETTE num-colors FALSE FALSE "")))
    
    (gimp-context-set-foreground old-fg)
    (gimp-context-set-background old-bg)
    (gimp-image-undo-enable img)
    (gimp-display-new img)
    ))


(script-fu-register "script-fu-old-stone"
		    "Old Stone..."
		    "                           "
		    "Jens Lautenbacher"
		    "Jens Lautenbacher"
		    "1997/1998"
		    ""
		    SF-STRING     "Text"                "The Gimp"
		    SF-FONT       "Font"                "Cooper Heavy"
		    SF-ADJUSTMENT "Font size (pixels)"  '(85 2 1000 1 10 0 1)
		    SF-COLOR      "Text color"          '(82 121 158)
		    SF-COLOR      "         "              '(255 255 255)
		    SF-ADJUSTMENT "                  "        '(5 1 1000 1 10 0 1)
		    SF-TOGGLE     "                              " FALSE
		    SF-TOGGLE     "            "             FALSE
		    SF-TOGGLE     "                     "       FALSE
		    SF-ADJUSTMENT "                           "   '(31 1 1000 1 10 0 1)
		    )

(script-fu-menu-register "script-fu-old-stone"
		    "<Toolbox>/Xtns/Extra Logos")