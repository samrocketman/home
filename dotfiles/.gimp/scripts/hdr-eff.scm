; HDR Fake Effect is a script for The GIMP
;
; This script produces a fake HDR effect on an image
;
; Follow the tut of jneurock@gimpology.com
; here the link :
; http://gimpology.com/submission/view/fake_hdr_look_in_gimp/
;
; The script use some code from Dodge burn is a script for The GIMP
; by  Harry Phillips <script-fu@tux.com.au>
;
; The script is located in "<Image> / Script-Fu / Enhance / HDR Fake Effect..."
;
; Last changed: 15th November 2008
;
; Copyright (C) 2008 Bui The Thang <vincent.valentine71@gmail.com>
;
; --------------------------------------------------------------------
; 
; Changelog:
;  Version 0.1
;    - Initial version
;  Version 0.2
;    - correct last step
;
; --------------------------------------------------------------------
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 3 of the License, or
; (at your option) any later version.  
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; 
; You should have received a copy of the GNU General Public License
; along with this program; if not, you can view the GNU General Public
; License version 3 at the web site http://www.gnu.org/licenses/gpl-3.0.html
; Alternatively you can write to the Free Software Foundation, Inc., 675 Mass
; Ave, Cambridge, MA 02139, USA.

(define (my-layer-stuff		myImage
				myLayer
				modeOp
				thinNum
				thickNum
	)

    ;Initiate some variables
    (let* (
	(firstTemp (car (gimp-layer-copy myLayer 1)))
	(thinTemp)
	(thickTemp)
	(merged)
    )


    ;Rename the layer
    (gimp-drawable-set-name firstTemp "First temp")

    ;Add the first layer to the image
    (gimp-image-add-layer myImage firstTemp 0)

    ;Desaturate the layer
    (gimp-desaturate firstTemp)

    ;Copy and add the dodge me layer as the thin layer
    (set! thinTemp (car (gimp-layer-copy firstTemp 1)))
    (gimp-image-add-layer myImage thinTemp 0)

    ;Blur the thin layer
    (plug-in-gauss 1 myImage thinTemp thinNum thinNum 0)

    (if (= modeOp 1)

	;Change the mode of the thin layer to lighten
    	(gimp-layer-set-mode thinTemp 10)

	;Change the mode of the thin layer to darken
    	(gimp-layer-set-mode thinTemp 9)
    )


    ;Blur the dodge me layer
    (plug-in-gauss 1 myImage firstTemp thickNum thickNum 0)

    ;Copy the dodge me layer as a new layer
    (set! thickTemp (car (gimp-layer-copy firstTemp 1)))

    ;Add the new layer to the image
    (gimp-image-add-layer myImage thickTemp 1)

    ;Merge the top layer down and keep track of the newly merged layer
    (set! merged (car (gimp-image-merge-down myImage thinTemp 0)))

    ;Change the mode of the dodge copy layer to difference mode
    (gimp-layer-set-mode merged 6)

    ;Merge the top layer down and keep track of the newly merged layer
    (set! merged (car (gimp-image-merge-down myImage merged 0)))

    (if (= modeOp 1)

	(begin
    		;Rename the layer
    		(gimp-drawable-set-name merged "Dodge channel")

    		;Change the mode of the dodge copy layer to dodge mode
    		(gimp-layer-set-mode merged 16)
	)

	(begin

    		;Rename the layer
    		(gimp-drawable-set-name merged "Burn channel")

    		;Change the mode of the dodge copy layer to dodge mode
    		(gimp-layer-set-mode merged 17)

		;Invert layer
		(gimp-invert merged)
	)
    )

    ;Return
    ))

(define (script-fu-fake-hdr-effect inImage inDrawable Opa-num)

	;Start an undo group so the process can be undone with one undo
	(gimp-image-undo-group-start inImage)

	 ;Select none
	(gimp-selection-none inImage)

	(let* (
		( theNewlayer (car (gimp-layer-copy inDrawable 1)))
		(theNewlayer1 0)
		(theNewlayer2 (car (gimp-layer-copy inDrawable 1)))
		(theNewlayer3 0)
		(subdra 0)
		(layerRGB 0)
		)
		
		(set! subdra (car (gimp-image-get-active-drawable inImage)))
		; Detect if it is RGB. Change the image RGB if it isn't already
		(set! layerRGB (car (gimp-drawable-is-rgb inDrawable)))
		(if (= layerRGB 0) (gimp-image-convert-rgb inDrawable))


		(gimp-image-add-layer inImage theNewlayer 0)
		(gimp-desaturate-full theNewlayer 2)
		(gimp-invert theNewlayer)
		(plug-in-softglow RUN-NONINTERACTIVE inImage theNewlayer 10 0.75 0.85)
		(gimp-layer-set-mode theNewlayer SOFTLIGHT-MODE )
		(gimp-layer-set-opacity theNewlayer 50)

		(set!  theNewlayer1 (car (gimp-layer-copy theNewlayer 1)))
			(gimp-image-add-layer inImage theNewlayer1 0)
			(gimp-layer-set-opacity theNewlayer1 75)
		
		(gimp-image-add-layer inImage theNewlayer2 0)
		(gimp-image-set-active-layer inImage theNewlayer2)
		(set! layerRGB (car (gimp-levels theNewlayer2 HISTOGRAM-VALUE 100 255 1.0 0 255)))
		(gimp-layer-set-opacity theNewlayer2 Opa-num)
		
		(set! subdra (car (gimp-image-flatten inImage)))

		(set! theNewlayer3 (car (gimp-layer-copy subdra 1)))
		(gimp-image-add-layer inImage theNewlayer3 0)
		(gimp-image-set-active-layer inImage theNewlayer3)		
		;Do the dodge layer first
		(my-layer-stuff inImage theNewlayer3 1 10 25)
		;Do the burn layer
		(my-layer-stuff inImage theNewlayer3 0 10 25) 
		
		(gimp-image-set-active-layer inImage theNewlayer3)
		(set! subdra (gimp-hue-saturation theNewlayer3 0 0 0 50))
		(set! subdra (gimp-levels theNewlayer3 HISTOGRAM-VALUE 25 225 1.0 0 255))

		(gimp-image-flatten inImage)

	)

	;Finish the undo group for the process
	(gimp-image-undo-group-end inImage)

	;Ensure the updated image is displayed now
	(gimp-displays-flush)
)

(script-fu-register
    "script-fu-fake-hdr-effect"
    "<Image>/Script-Fu/Enhance/Fake HDR Effect..."
    "Make a photo to fake HDR with GIMP"
    "Bui The Thang  <vincent.valentine71@gmail.com>"
    "Bui The Thang"
    "Nov, 2008"
    "RGB*"
    SF-IMAGE    "Image"        0
    SF-DRAWABLE    "Drawable"    0
    SF-ADJUSTMENT   _"Dark Layer Opacity:"     '(35 5 60 1 1 0 1)
)
