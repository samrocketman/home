; histogram_match.scm
; by Rob Antonishen
; http://ffaat.pointclark.net
 
; Version 1.4 (20090520)
;
; Changes
; 1.1 - added options to copy from image or equalize.
;     - added option to resize images for histogram sampling (speed improvement)
; 1.2 - changed calculation methods (Thanks to isomage at http://axiscity.hexamon.net/users/isomage/ )
;     - added preprocessing of saturation and contrast
; 1.3 - changed to always use lp filtering on histograms (thanks saulgoode at gimptalk!)
;     - removed equalize option
; 1.4 - Provides Additional modes of matching, HSV, LAB, and equalize now an option
 
; Description
;
; tries to map the histogram from one image to the current image.
;
 
; License:
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
; The GNU Public License is available at
; http://www.gnu.org/copyleft/gpl.html


;make all array elements sum to 1
(define (array-normalize array)
  (let ((total 0)(i 0))
    (while (< i (vector-length array))
      (set! total (+ total (vector-ref array i)))
      (set! i (+ i 1)))
    (set! i 0)
    (while (< i (vector-length array))
      (vector-set! array i (/ (vector-ref array i) total))
      (set! i (+ i 1)))))

;change array to be an imcremental array
(define (array-incremental array)
  (if (> (vector-length array) 1) 
    (let ((i 1))
      (while (< i (vector-length array))
        (vector-set! array i (+ (vector-ref array i) (vector-ref array (- i 1))))
        (set! i (+ i 1))))))

;returns a low pass filtered histogram with gaps interpolated as an array
(define (get-hist-lpf drawable chan)
  (let* (
      (i 0)
      (hist (make-vector 256))
      (filt (make-vector 256))
      (last-v 0)
      (last-x 0)
      (max-v 0)
      (alpha 0.3) ; filter smoothing
      (span 1)
      (delta-v 0)
      )
    (set! i 0)
    (while (< i 256)
      (set! last-v (car (last (gimp-histogram drawable chan i i))))
      (vector-set! hist i last-v)
      (set! max-v (max max-v last-v))
      (set! i (+ i 1))
      )
    (set! hist (list->vector (map (lambda (x) (* (/ x max-v) 255)) (vector->list hist))))
    ; filter left-to-right
    (vector-set! filt 0 (vector-ref hist 0))
    (set! i 1)
    (while (< i 256)
      (set! last-v (vector-ref filt (- i 1)))
      (vector-set! filt i (+ last-v (* alpha (- (vector-ref hist i) last-v))))
      (set! i (+ i 1))
      )

    ; adjust by filtering right-to-left and taking minimum value
    (set! i 255)
    (vector-set! filt i (min (vector-ref filt i) (vector-ref hist i)))
    (while (> i 0)
      (set! last-v (vector-ref filt i))
      (set! i (- i 1))
      (vector-set! filt i (min
          (vector-ref filt i)
          (+ last-v (* alpha (- (vector-ref hist i) last-v)))
          )
        )
      )
    ; interpolate histogram whereever filtered histogram is less than original
    (set! last-v (vector-ref hist 0))
    (set! last-x 1)
    (set! i 1)
    (while (< i 256)
      (while (and (< i 256)
                  (< (vector-ref hist i) (vector-ref filt i))
                  )
        (set! i (+ i 1))
        )
      (set! span (- i last-x -1))
      (set! delta-v (- (vector-ref hist i) last-v))
      (while (and (< i 256)
                  (< last-x i)
                  )
        (vector-set! hist last-x (+ last-v (* (- span (- i last-x)) (/ delta-v span))))
        (set! last-x (+ last-x 1))
        )
      (set! last-v (vector-ref hist i))
      (set! i (+ i 1))
      (set! last-x i)
      )
    hist
    )
  )

;returns the raw histogram  with values 0-1 as an array
(define (get-hist drawable chan)
  (let* (
      (i 0)
      (hist (make-vector 256))
      )
    (set! i 0)
    (while (< i 256)
      (vector-set! hist i (car (last (gimp-histogram drawable chan i i))))
      (set! i (+ i 1))
      )
    hist
    )
  )

;returns a flat histogram
(define (get-hist-flat)
  (let* (
      (i 0)
      (hist (make-vector 256))
      )
    (set! i 0)
    (while (< i 256)
      (vector-set! hist i 1)
      (set! i (+ i 1))
      )
    hist
    )
  )

;performs the histogram match on a single greyscale channel (layer) 
;separate from and to to use scaled, apply is the target layer, smooth is TRUE otr FALSE
;to interpolate the spaces
(define (hist-xfer drawFrom drawTo drawApply smooth equalize)
  (let*
    ((varNumBytes 256)
    (varSrcCurve     (cons-array varNumBytes 'double))
    (varTgtCurve     (cons-array varNumBytes 'double))
    (varAdjCurve     (cons-array varNumBytes 'byte))
    (counter 0)
    (counter2 0)
    (checkval 0))

  ;get curves
  (gimp-progress-pulse)
  (if (eq? equalize TRUE)
    (set! varSrcCurve (get-hist-flat))
    (set! varSrcCurve (if (eq? smooth TRUE) (get-hist-lpf drawFrom HISTOGRAM-VALUE) (get-hist drawFrom HISTOGRAM-VALUE))))

  (gimp-progress-pulse)
  (set! varTgtCurve (if (eq? smooth TRUE) (get-hist-lpf drawTo HISTOGRAM-VALUE) (get-hist drawTo HISTOGRAM-VALUE)))

  ;normalize, convert to incremental
  (gimp-progress-pulse)
  (array-normalize varSrcCurve)
  (gimp-progress-pulse)
  (array-incremental varSrcCurve)
  (gimp-progress-pulse)
  (array-normalize varTgtCurve)
  (gimp-progress-pulse)
  (array-incremental varTgtCurve)

  (gimp-progress-pulse)
  (gimp-progress-set-text "Matching...")
  ; find the match on the source histogram 
  (set! counter 0)
  (while (< counter varNumBytes)
    (set! counter2 0)
    (set! checkval (vector-ref varTgtCurve counter))
    (while (and (< counter2 varNumBytes) (<= (vector-ref varSrcCurve counter2) checkval))
      (set! counter2 (+ counter2 1)))
    (aset varAdjCurve counter counter2) ;
    (gimp-progress-pulse)
    (set! counter (+ counter 1)))

  ;apply the curve
  (gimp-curves-explicit drawApply HISTOGRAM-VALUE varNumBytes varAdjCurve)))


;debug function
(define (ma array)
  (let ((i 0) (msg ""))
    (while (< i (vector-length array))
      (set! msg (string-append msg (number->string (vector-ref array i)) " "))
      (set! i (+ i 1)))
    (gimp-message msg)))
 
(define (script-fu-histogram-match img inLayer inSource inEqualize inMode inSmooth inSaturation inLightness inScale inSize)
  (let*
    ((imgSrc 0)
    (imgTgt 0)
    (imgSrcDecomp 0)
    (imgTgtDecomp 0)
    (imgInlayerDecomp 0)
    (layerSrc 0)
    (layerTgt 0)
    (buffname "histmatch"))

    ;  it begins here
    (gimp-context-push)
    (gimp-image-undo-group-start img)
    (gimp-progress-pulse)
    ;work on duplicates
    (set! buffname (car (gimp-edit-named-copy inLayer buffname)))
    (set! imgTgt (car (gimp-edit-named-paste-as-new buffname)))
    (set! layerTgt (vector-ref (cadr (gimp-image-get-layers imgTgt)) 0))   
    (set! buffname (car (gimp-edit-named-copy inSource buffname)))
    (set! imgSrc (car (gimp-edit-named-paste-as-new buffname)))
    (set! layerSrc (vector-ref (cadr (gimp-image-get-layers imgSrc)) 0))   

    ;disable undo on all temp images
    (gimp-image-undo-disable imgTgt)
    (gimp-image-undo-disable imgSrc)

    ;scale if checked
    (if (= inScale TRUE)
    (begin
      (gimp-image-scale-full imgTgt (min inSize (car (gimp-drawable-width layerTgt))) 
                               (min inSize (car (gimp-drawable-height layerTgt))) INTERPOLATION-NONE) 
      (gimp-image-scale-full imgSrc (min inSize (car (gimp-drawable-width layerSrc))) 
                               (min inSize (car (gimp-drawable-height layerSrc))) INTERPOLATION-NONE)))

    (gimp-progress-pulse)

    ; preprocesing
    (if (not (and (= inSaturation 0) (= inLightness 0)))
      (gimp-hue-saturation layerSrc ALL-HUES 0 inLightness inSaturation))

    (gimp-progress-pulse)
    ;The main part
    (cond
      ((= inMode 0) ;value
        (hist-xfer layerSrc layerTgt inLayer inSmooth inEqualize))
      
      ((= inMode 1) ; ;RGB
        (set! imgSrcDecomp (car (plug-in-decompose RUN-NONINTERACTIVE imgSrc layerSrc "RGB" TRUE)))
        (set! imgTgtDecomp (car (plug-in-decompose RUN-NONINTERACTIVE imgTgt layerTgt "RGB" TRUE)))
        (set! imgInlayerDecomp (car (plug-in-decompose RUN-NONINTERACTIVE img inLayer "RGB" TRUE)))
        (gimp-image-undo-disable imgSrcDecomp)
        (gimp-image-undo-disable imgTgtDecomp)
        (gimp-image-undo-disable imgInlayerDecomp)
        (hist-xfer (vector-ref (cadr (gimp-image-get-layers imgSrcDecomp)) 0) 
                   (vector-ref (cadr (gimp-image-get-layers imgTgtDecomp)) 0)
                   (vector-ref (cadr (gimp-image-get-layers imgInlayerDecomp)) 0) inSmooth inEqualize)      
        (hist-xfer (vector-ref (cadr (gimp-image-get-layers imgSrcDecomp)) 1) 
                   (vector-ref (cadr (gimp-image-get-layers imgTgtDecomp)) 1)
                   (vector-ref (cadr (gimp-image-get-layers imgInlayerDecomp)) 1) inSmooth inEqualize)      
        (hist-xfer (vector-ref (cadr (gimp-image-get-layers imgSrcDecomp)) 2) 
                   (vector-ref (cadr (gimp-image-get-layers imgTgtDecomp)) 2)
                   (vector-ref (cadr (gimp-image-get-layers imgInlayerDecomp)) 2) inSmooth inEqualize)      
        (plug-in-recompose RUN-NONINTERACTIVE imgInlayerDecomp (vector-ref (cadr (gimp-image-get-layers imgInlayerDecomp)) 0))
        (gimp-image-delete imgSrcDecomp)
        (gimp-image-delete imgTgtDecomp)
        (gimp-image-delete imgInlayerDecomp))

      ((= inMode 2) ; HSV 
        (set! imgSrcDecomp (car (plug-in-decompose RUN-NONINTERACTIVE imgSrc layerSrc "HSV" TRUE)))
        (set! imgTgtDecomp (car (plug-in-decompose RUN-NONINTERACTIVE imgTgt layerTgt "HSV" TRUE)))
        (set! imgInlayerDecomp (car (plug-in-decompose RUN-NONINTERACTIVE img inLayer "HSV" TRUE)))
        (gimp-image-undo-disable imgSrcDecomp)
        (gimp-image-undo-disable imgTgtDecomp)
        (gimp-image-undo-disable imgInlayerDecomp)
        (hist-xfer (vector-ref (cadr (gimp-image-get-layers imgSrcDecomp)) 0) 
                   (vector-ref (cadr (gimp-image-get-layers imgTgtDecomp)) 0)
                   (vector-ref (cadr (gimp-image-get-layers imgInlayerDecomp)) 0) inSmooth inEqualize)      
        (hist-xfer (vector-ref (cadr (gimp-image-get-layers imgSrcDecomp)) 1) 
                   (vector-ref (cadr (gimp-image-get-layers imgTgtDecomp)) 1)
                   (vector-ref (cadr (gimp-image-get-layers imgInlayerDecomp)) 1) inSmooth inEqualize)      
        (hist-xfer (vector-ref (cadr (gimp-image-get-layers imgSrcDecomp)) 2) 
                   (vector-ref (cadr (gimp-image-get-layers imgTgtDecomp)) 2)
                   (vector-ref (cadr (gimp-image-get-layers imgInlayerDecomp)) 2) inSmooth inEqualize)      
        (plug-in-recompose RUN-NONINTERACTIVE imgInlayerDecomp (vector-ref (cadr (gimp-image-get-layers imgInlayerDecomp)) 0))
        (gimp-image-delete imgSrcDecomp)
        (gimp-image-delete imgTgtDecomp)
        (gimp-image-delete imgInlayerDecomp))

      ((= inMode 3) ; HS
        (set! imgSrcDecomp (car (plug-in-decompose RUN-NONINTERACTIVE imgSrc layerSrc "HSV" TRUE)))
        (set! imgTgtDecomp (car (plug-in-decompose RUN-NONINTERACTIVE imgTgt layerTgt "HSV" TRUE)))
        (set! imgInlayerDecomp (car (plug-in-decompose RUN-NONINTERACTIVE img inLayer "HSV" TRUE)))
        (gimp-image-undo-disable imgSrcDecomp)
        (gimp-image-undo-disable imgTgtDecomp)
        (gimp-image-undo-disable imgInlayerDecomp)
        (hist-xfer (vector-ref (cadr (gimp-image-get-layers imgSrcDecomp)) 0) 
                   (vector-ref (cadr (gimp-image-get-layers imgTgtDecomp)) 0)
                   (vector-ref (cadr (gimp-image-get-layers imgInlayerDecomp)) 0) inSmooth inEqualize)      
        (hist-xfer (vector-ref (cadr (gimp-image-get-layers imgSrcDecomp)) 1) 
                   (vector-ref (cadr (gimp-image-get-layers imgTgtDecomp)) 1)
                   (vector-ref (cadr (gimp-image-get-layers imgInlayerDecomp)) 1) inSmooth inEqualize)      
        (plug-in-recompose RUN-NONINTERACTIVE imgInlayerDecomp (vector-ref (cadr (gimp-image-get-layers imgInlayerDecomp)) 0))
        (gimp-image-delete imgSrcDecomp)
        (gimp-image-delete imgTgtDecomp)
        (gimp-image-delete imgInlayerDecomp))

      ((= inMode 4) ; LAB 
        (set! imgSrcDecomp (car (plug-in-decompose RUN-NONINTERACTIVE imgSrc layerSrc "LAB" TRUE)))
        (set! imgTgtDecomp (car (plug-in-decompose RUN-NONINTERACTIVE imgTgt layerTgt "LAB" TRUE)))
        (set! imgInlayerDecomp (car (plug-in-decompose RUN-NONINTERACTIVE img inLayer "LAB" TRUE)))
        (gimp-image-undo-disable imgSrcDecomp)
        (gimp-image-undo-disable imgTgtDecomp)
        (gimp-image-undo-disable imgInlayerDecomp)
        (hist-xfer (vector-ref (cadr (gimp-image-get-layers imgSrcDecomp)) 0) 
                   (vector-ref (cadr (gimp-image-get-layers imgTgtDecomp)) 0)
                   (vector-ref (cadr (gimp-image-get-layers imgInlayerDecomp)) 0) inSmooth inEqualize)      
        (hist-xfer (vector-ref (cadr (gimp-image-get-layers imgSrcDecomp)) 1) 
                   (vector-ref (cadr (gimp-image-get-layers imgTgtDecomp)) 1)
                   (vector-ref (cadr (gimp-image-get-layers imgInlayerDecomp)) 1) inSmooth inEqualize)      
        (hist-xfer (vector-ref (cadr (gimp-image-get-layers imgSrcDecomp)) 2) 
                   (vector-ref (cadr (gimp-image-get-layers imgTgtDecomp)) 2)
                   (vector-ref (cadr (gimp-image-get-layers imgInlayerDecomp)) 2) inSmooth inEqualize)      
        (plug-in-recompose RUN-NONINTERACTIVE imgInlayerDecomp (vector-ref (cadr (gimp-image-get-layers imgInlayerDecomp)) 0))
        (gimp-image-delete imgSrcDecomp)
        (gimp-image-delete imgTgtDecomp)
        (gimp-image-delete imgInlayerDecomp))

      ((= inMode 5) ; A & B
        (set! imgSrcDecomp (car (plug-in-decompose RUN-NONINTERACTIVE imgSrc layerSrc "LAB" TRUE)))
        (set! imgTgtDecomp (car (plug-in-decompose RUN-NONINTERACTIVE imgTgt layerTgt "LAB" TRUE)))
        (set! imgInlayerDecomp (car (plug-in-decompose RUN-NONINTERACTIVE img inLayer "LAB" TRUE)))
        (gimp-image-undo-disable imgSrcDecomp)
        (gimp-image-undo-disable imgTgtDecomp)
        (gimp-image-undo-disable imgInlayerDecomp)
        (hist-xfer (vector-ref (cadr (gimp-image-get-layers imgSrcDecomp)) 1) 
                   (vector-ref (cadr (gimp-image-get-layers imgTgtDecomp)) 1)
                   (vector-ref (cadr (gimp-image-get-layers imgInlayerDecomp)) 1) inSmooth inEqualize)      
        (hist-xfer (vector-ref (cadr (gimp-image-get-layers imgSrcDecomp)) 2) 
                   (vector-ref (cadr (gimp-image-get-layers imgTgtDecomp)) 2)
                   (vector-ref (cadr (gimp-image-get-layers imgInlayerDecomp)) 2) inSmooth inEqualize)      
        (plug-in-recompose RUN-NONINTERACTIVE imgInlayerDecomp (vector-ref (cadr (gimp-image-get-layers imgInlayerDecomp)) 0))
        (gimp-image-delete imgSrcDecomp)
        (gimp-image-delete imgTgtDecomp)
        (gimp-image-delete imgInlayerDecomp))

      ((= inMode 6) ; YCbCr_ITU_R470 
        (set! imgSrcDecomp (car (plug-in-decompose RUN-NONINTERACTIVE imgSrc layerSrc "YCbCr_ITU_R470" TRUE)))
        (set! imgTgtDecomp (car (plug-in-decompose RUN-NONINTERACTIVE imgTgt layerTgt "YCbCr_ITU_R470" TRUE)))
        (set! imgInlayerDecomp (car (plug-in-decompose RUN-NONINTERACTIVE img inLayer "YCbCr_ITU_R470" TRUE)))
        (gimp-image-undo-disable imgSrcDecomp)
        (gimp-image-undo-disable imgTgtDecomp)
        (gimp-image-undo-disable imgInlayerDecomp)
        (hist-xfer (vector-ref (cadr (gimp-image-get-layers imgSrcDecomp)) 0) 
                   (vector-ref (cadr (gimp-image-get-layers imgTgtDecomp)) 0)
                   (vector-ref (cadr (gimp-image-get-layers imgInlayerDecomp)) 0) inSmooth inEqualize)      
        (hist-xfer (vector-ref (cadr (gimp-image-get-layers imgSrcDecomp)) 1) 
                   (vector-ref (cadr (gimp-image-get-layers imgTgtDecomp)) 1)
                   (vector-ref (cadr (gimp-image-get-layers imgInlayerDecomp)) 1) inSmooth inEqualize)      
        (hist-xfer (vector-ref (cadr (gimp-image-get-layers imgSrcDecomp)) 2) 
                   (vector-ref (cadr (gimp-image-get-layers imgTgtDecomp)) 2)
                   (vector-ref (cadr (gimp-image-get-layers imgInlayerDecomp)) 2) inSmooth inEqualize)      
        (plug-in-recompose RUN-NONINTERACTIVE imgInlayerDecomp (vector-ref (cadr (gimp-image-get-layers imgInlayerDecomp)) 0))
        (gimp-image-delete imgSrcDecomp)
        (gimp-image-delete imgTgtDecomp)
        (gimp-image-delete imgInlayerDecomp))

      ((= inMode 7) ; YCbCr_ITU_R470 Keep Y
        (set! imgSrcDecomp (car (plug-in-decompose RUN-NONINTERACTIVE imgSrc layerSrc "YCbCr_ITU_R470" TRUE)))
        (set! imgTgtDecomp (car (plug-in-decompose RUN-NONINTERACTIVE imgTgt layerTgt "YCbCr_ITU_R470" TRUE)))
        (set! imgInlayerDecomp (car (plug-in-decompose RUN-NONINTERACTIVE img inLayer "YCbCr_ITU_R470" TRUE)))
        (gimp-image-undo-disable imgSrcDecomp)
        (gimp-image-undo-disable imgTgtDecomp)
        (gimp-image-undo-disable imgInlayerDecomp)
        (hist-xfer (vector-ref (cadr (gimp-image-get-layers imgSrcDecomp)) 1) 
                   (vector-ref (cadr (gimp-image-get-layers imgTgtDecomp)) 1)
                   (vector-ref (cadr (gimp-image-get-layers imgInlayerDecomp)) 1) inSmooth inEqualize)      
        (hist-xfer (vector-ref (cadr (gimp-image-get-layers imgSrcDecomp)) 2) 
                   (vector-ref (cadr (gimp-image-get-layers imgTgtDecomp)) 2)
                   (vector-ref (cadr (gimp-image-get-layers imgInlayerDecomp)) 2) inSmooth inEqualize)      
        (plug-in-recompose RUN-NONINTERACTIVE imgInlayerDecomp (vector-ref (cadr (gimp-image-get-layers imgInlayerDecomp)) 0))
        (gimp-image-delete imgSrcDecomp)
        (gimp-image-delete imgTgtDecomp)
        (gimp-image-delete imgInlayerDecomp))
     )

  ;cleanup duplicate images
  (gimp-image-delete imgSrc)
  (gimp-image-delete imgTgt)

  ;done
  (gimp-progress-end)
  (gimp-image-undo-group-end img)
  (gimp-displays-flush)
  (gimp-context-pop)))
 
(script-fu-register "script-fu-histogram-match"
                    "<Image>/Colors/Map/Match Histogram..."
                    "Match the histogram of another image"
                    "Rob Antonishen"
                    "Rob Antonishen"
                    "April 2009"
                    "RGB*"
                    SF-IMAGE      "image"      0
                    SF-DRAWABLE   "drawable"   0
                    SF-DRAWABLE   "Use Histogram From (Source)"   0
                    SF-TOGGLE     "Equalize Instead of Matching" FALSE                    
                    SF-OPTION     "Channels to Use" (list "Value" "RGB" 
                                                              "HSV" "HSV - Preserve Value" 
                                                              "LAB" "LAB - Preserve Luma" 
                                                              "YCbCr" "YCbCr - Preserve Luma")
                    SF-TOGGLE     "Smooth Histograms" TRUE
                    SF-ADJUSTMENT "Source Saturation Adjust"  (list 0 -100 100 1 10 0 SF-SLIDER)
                    SF-ADJUSTMENT "Source Lightness Adjust"    (list 0 -100 100 1 10 0 SF-SLIDER)
                    SF-TOGGLE     "Analyze Scaled Image (faster)" TRUE
                    SF-ADJUSTMENT "Scale Size"  (list 256 64 1024 8 64 0 SF-SPINNER)
)