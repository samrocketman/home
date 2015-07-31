(define (script-fu-thick-oil-paint image
                                   drawable)
  (let* ((original-layer FALSE)
         (glop-layer FALSE)
         (mask-channel FALSE))

    (gimp-undo-push-group-start image)
    (set! original-layer (car (gimp-image-get-active-layer image)))
    (plug-in-oilify 1 image original-layer 7 1)
    (set! glop-layer (car (gimp-layer-copy original-layer TRUE)))
    (gimp-image-add-layer image glop-layer -1)
    (set! mask-channel (car (gimp-layer-create-mask glop-layer WHITE-MASK)))
    (gimp-image-add-layer-mask image glop-layer mask-channel)
    (gimp-edit-copy glop-layer)
    (gimp-floating-sel-anchor (car (gimp-edit-paste mask-channel FALSE)))
    (gimp-invert mask-channel)
    (gimp-brightness-contrast mask-channel 0 85)
    (gimp-image-remove-layer-mask image glop-layer APPLY)
    (plug-in-bump-map 1 image glop-layer glop-layer 160.0 25.0 16 0 0 0 0 1 0 0)
    (plug-in-apply-canvas 1 image original-layer 0 4)
    (gimp-image-merge-down image glop-layer CLIP-TO-BOTTOM-LAYER)
    (gimp-undo-push-group-end image)
    (gimp-displays-flush)
))

(script-fu-register "script-fu-thick-oil-paint"
                    _"<Image>/Script-Fu/Alchemy/Thick Oil Paint"
                    "Applies a heavy oil effect to the specified drawable."
                    "David A. Bartold <foxx@mail.utexas.edu>"
                    "David A. Bartold"
                    "12/17/00"
                    "RGB* GRAY*"
                    SF-IMAGE "Image" 0
                    SF-DRAWABLE "Drawable" 0)
