;
; The GIMP -- an image manipulation program
; Copyright (C) 1995 Spencer Kimball and Peter Mattis
;
; Sepia toning script  for GIMP 2.4
; by Jakub Klawiter 05.2007 - 11.2007
;
; Tags: photo, colcor, old, sepia
;
; Author statement:
; just to learn how all it works ;-)
; this is a copy of Sepia Toning tutorial
; http://www.gimp.org/tutorials/Sepia_Toning/
; by Eric R. Jeschke
;
; --------------------------------------------------------------------
; Distributed by Gimp FX Foundry project
; --------------------------------------------------------------------
;   - Changelog -
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
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (script-fu-Sepia_Toning img drawable desaturate mergeLayers color)
	(let* (
		(sepiaLayer 0)
		(maskLayer 0)
		(mask 0)
		)
; Start an undo group. Everything between the start and the end will
; be carried out if an undo command is issued.
    (gimp-image-undo-group-start img)
    (gimp-displays-flush)

; STEP 2 - copy and desaturate (optional) source layer

    (set! sepiaLayer
        (car
            (gimp-layer-copy
                drawable
                TRUE
            )
        )
    )
    (gimp-layer-set-name sepiaLayer "Sepia")
    (gimp-image-add-layer img sepiaLayer -1)



    (if (equal? desaturate TRUE)
        (gimp-desaturate sepiaLayer)
        ()
    )



; STEP 3 Set foreground color
    (gimp-context-set-foreground color)

; STEP 4
; Create a new layer
    (set! maskLayer
        (car
            (gimp-layer-new
                img                             ; image handle
                (car (gimp-image-width img))    ; width of layer
                (car (gimp-image-height img))   ; height
                1                               ; type (RGB, RGBA, etc.)
                "Sepia Mask"                    ; name of layer
                100                             ; opacity
                COLOR-MODE                      ; mode
            )
        )
    )


; Add the new layer to the image
    (gimp-image-add-layer img maskLayer -1)

    (gimp-drawable-fill maskLayer 0)

; STEP 5
    (set! mask
        (car
            (gimp-layer-create-mask maskLayer 0)
        )
    )
    (gimp-layer-add-mask maskLayer mask)

; STEP 6, 7 Copy image into Sepia Layer mask, and than invert it
    (gimp-layer-resize-to-image-size sepiaLayer) ; workaround because i cannot 'paste in place' into mask
    (gimp-edit-copy sepiaLayer)

    (let ((selection (car (gimp-edit-paste mask 0))))
        (gimp-floating-sel-anchor selection)
    )
    (gimp-invert mask)

; merge layer down
    (if (equal? mergeLayers TRUE)
        (gimp-image-merge-down
            img             ; img
            maskLayer      ; upper layer
            0               ; merge type [0,1,2]
        )
        ()
    )

; Complete the undo group
    (gimp-image-undo-group-end img)
	) ; let* variables definition
)



(script-fu-register "script-fu-Sepia_Toning"
    "Sepia Toning"
    "Automatic version of great
Sepia Toning tutorial
by Eric R. Jeschke (redskiesatnight.com/)

www.gimp.org/tutorials/Sepia_Toning/"
    "Jakub Klawiter"
    ""
    "03.2007"
    "RGB RGBA"
    SF-IMAGE      "img"                 0
    SF-DRAWABLE   "drawable"            0
    SF-TOGGLE     "Desaturate source"   FALSE
    SF-TOGGLE     "Merge layers"        FALSE
    SF-COLOR      "color"               '(162 138 101))

(script-fu-menu-register
    "script-fu-Sepia_Toning"
    "<Image>/FX-Foundry/Photo/Effects"
)
