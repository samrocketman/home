; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

;; Command is installed in "Filters->Animations->Save layers..."
;;
;; A template string should be provided which fits the form: prefix~~~~.ext
;; where prefix is a character string (optionally null).
;;       ~~~~ represents the digits of the frame number, one ~ per digit
;;       ext is the filename extension (which also specifies the format)
;; the tildas are optional and four digits will be assumed if omitted.
;; an extension of .png is assumed if one is not provided
;; the period is significant, if PNG is not to be assumed
;;
;; A checkbox provides the option of using the layernames for the
;; filenames. The extension given in the template is used to determine
;; the file type. Animation settings (delay and frame disposal) are not
;; included as part of the filename.
;;
;; When saving to GIF files, the GIMP's default values are used to
;; convert to INDEXED mode (255 color palette, no dithering).
;; Note: this is done on a layer-by-layer basis, so more colors may result
;; than if the entire image were converted to INDEXED before saving.


(define (script-fu-save-anim-layers orig-image drawable
                                    template
                                    rename?)
  (define (get-all-layers img)
    (let* (
        (all-layers (gimp-image-get-layers img))
        (i (car all-layers))
        (bottom-to-top ())
        )
      (set! all-layers (cadr all-layers))
      (while (> i 0)
        (set! bottom-to-top (append bottom-to-top (cons (aref all-layers (- i 1)) '())))
        (set! i (- i 1))
        )
      bottom-to-top
      )
    )
  (define (save-layer orig-image layer name)
    (let* (
        (image 0)
        (buffer "")
        )
      (set! buffer (car (gimp-edit-named-copy layer "temp-copy")))
      (set! image (car (gimp-edit-named-paste-as-new buffer)))
      (when (and (not (= (car (gimp-image-base-type image)) INDEXED))
                 (string-ci=? (car (last (strbreakup name "."))) "gif"))
        (gimp-image-convert-indexed image
                                    NO-DITHER
                                    MAKE-PALETTE
                                    255
                                    FALSE
                                    FALSE
                                    "")
        )
      (gimp-file-save RUN-NONINTERACTIVE image (car (gimp-image-get-active-layer image)) name name)
      (gimp-buffer-delete buffer)
      (gimp-image-delete image)
      )
    )
  (let* (
      (image nil)
      (layers nil)
      (fullname "")
      (basename "")
      (layername "")
      (format "")
      (layerpos 1)
      (framenum "")
      (settings "")
      (default-extension "png")
      (extension "png")
      (orig-selection 0)
      )
    (gimp-image-undo-disable orig-image)
    (set! orig-selection (car (gimp-selection-save orig-image)))
    (gimp-selection-none orig-image)
    (set! image (car (plug-in-animationunoptimize RUN-NONINTERACTIVE orig-image drawable)))

    (set! extension (strbreakup template "."))
    (set! extension (if (> (length extension) 1)
                      (car (last extension))
                      default-extension))
    (when (= (string-length extension) 0)
      (set! default-extension "png"))
    (when (= rename? TRUE)
      (set! format (strbreakup template "~"))
      (if (> (length format) 1)
        (begin
          (set! basename (car format))
          (set! format (cdr format))
          (set! format (cons "" (butlast format)))
          (set! format (string-append "0" (unbreakupstr format "0")))
          )
        (begin
          (set! basename (car (strbreakup template ".")))
          (set! format "0000")
          )
        )
      )
    (set! layers (get-all-layers image))
    (while (pair? layers)
      (if (= rename? TRUE)
        (begin
          (set! framenum (number->string layerpos))
          (set! framenum (string-append
                (substring format 0 (- (string-length format)
                                       (string-length framenum))) framenum))
          (set! fullname (string-append basename framenum))
          )
        (begin
          (set! fullname (car (strbreakup
                           (car (gimp-drawable-get-name (car layers))) "(")))
          (gimp-drawable-set-name (car layers) fullname)
          (set! fullname (car (gimp-drawable-get-name (car layers))))
          )
        )
      (set! fullname (string-append fullname "." extension))
      (save-layer image (car layers) fullname)
      (set! layers (cdr layers))
      (set! layerpos (+ layerpos 1))
      )
    (gimp-image-delete image)
    (gimp-selection-load orig-selection)
    (gimp-image-remove-channel orig-image orig-selection)
    (gimp-image-undo-enable orig-image)
    )
  )

(script-fu-register "script-fu-save-anim-layers"
 "<Image>/Filters/Animation/S_ave layers..."
 "Save each layer to a file."
 "Saul Goode"
 "Saul Goode"
 "3/11/2008"
 ""
 SF-IMAGE    "Image"    0
 SF-DRAWABLE "Drawable" 0
 SF-STRING "Name Template (~ replaced by layer position)" "frame_~~~~.gif"
 SF-TOGGLE "Rename (ex: 'frame__0001')" TRUE
 )
