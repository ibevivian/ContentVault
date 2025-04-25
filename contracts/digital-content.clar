;; ContentVault - A decentralized digital content licensing marketplace
;; Built on Stacks blockchain using Clarity language

;; Define contract data storage

;; Content details
(define-map contents
    { content-id: uint }
    {
        owner: principal,
        title: (string-utf8 100),
        description: (string-utf8 500),
        content-hash: (buff 32),
        creation-time: uint,
        license-price: uint,
        license-duration-days: uint,
        is-active: bool
    }
)

;; Content royalty splits
(define-map royalty-splits
    { content-id: uint, beneficiary: principal }
    { percentage: uint }  ;; Percentage stored as basis points (1% = 100)
)

;; Active licenses
(define-map licenses
    { content-id: uint, licensee: principal }
    {
        expiration: uint,
        license-type: (string-utf8 20),
        payment-amount: uint
    }
)

;; Content counters
(define-data-var content-counter uint u0)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u1)
(define-constant ERR-ALREADY-EXISTS u2)
(define-constant ERR-DOES-NOT-EXIST u3)
(define-constant ERR-INVALID-INPUT u4)
(define-constant ERR-INACTIVE u5)
(define-constant ERR-INSUFFICIENT-FUNDS u6)
(define-constant ERR-INVALID-ROYALTY u7)
(define-constant ERR-ZERO-PRICE u8)
(define-constant ERR-ZERO-DURATION u9)
(define-constant ERR-INVALID-CONTENT-ID u10)
(define-constant ERR-INVALID-BENEFICIARY u11)
(define-constant ERR-INVALID-TITLE u12)
(define-constant ERR-INVALID-DESCRIPTION u13)
(define-constant ERR-INVALID-CONTENT-HASH u14)
(define-constant ERR-INVALID-LICENSE-TYPE u15)

;; Read-only functions

(define-read-only (get-content-details (content-id uint))
    (match (map-get? contents { content-id: content-id })
        content-details (ok content-details)
        (err ERR-DOES-NOT-EXIST)
    )
)

(define-read-only (get-license-details (content-id uint) (licensee principal))
    (match (map-get? licenses { content-id: content-id, licensee: licensee })
        license (ok license)
        (err ERR-DOES-NOT-EXIST)
    )
)

(define-read-only (get-royalty-split (content-id uint) (beneficiary principal))
    (match (map-get? royalty-splits { content-id: content-id, beneficiary: beneficiary })
        split (ok split)
        (err ERR-DOES-NOT-EXIST)
    )
)

(define-read-only (is-license-active (content-id uint) (licensee principal))
    (match (map-get? licenses { content-id: content-id, licensee: licensee })
        license (< block-height (get expiration license))
        false
    )
)

(define-read-only (get-total-content-count)
    (var-get content-counter)
)

;; Validation helpers
(define-read-only (is-valid-content-id (content-id uint))
    (and 
        (>= content-id u1)
        (<= content-id (var-get content-counter))
    )
)

;; String validation helpers
(define-read-only (is-valid-string (str (string-utf8 500)))
    (> (len str) u0)
)

;; Buffer validation helpers
(define-read-only (is-valid-hash (hash (buff 32)))
    (is-some hash)
)

;; Public functions

;; Register new content
(define-public (register-content 
    (title (string-utf8 100)) 
    (description (string-utf8 500)) 
    (content-hash (buff 32))
    (license-price uint)
    (license-duration-days uint))
    
    (begin
        ;; Validate inputs
        (asserts! (is-valid-string title) (err ERR-INVALID-TITLE))
        (asserts! (is-valid-string description) (err ERR-INVALID-DESCRIPTION))
        (asserts! (is-valid-hash content-hash) (err ERR-INVALID-CONTENT-HASH))
        (asserts! (> license-price u0) (err ERR-ZERO-PRICE))
        (asserts! (> license-duration-days u0) (err ERR-ZERO-DURATION))
        
        (let 
            ((content-id (+ (var-get content-counter) u1))
             (validated-title title)  ;; Using validated variables to satisfy compiler
             (validated-description description)
             (validated-hash content-hash))
            
            ;; Store content details with validated inputs
            (map-set contents 
                { content-id: content-id }
                {
                    owner: tx-sender,
                    title: validated-title,
                    description: validated-description,
                    content-hash: validated-hash,
                    creation-time: block-height,
                    license-price: license-price,
                    license-duration-days: license-duration-days,
                    is-active: true
                }
            )
            
            ;; Set default royalty split (100% to creator)
            (map-set royalty-splits
                { content-id: content-id, beneficiary: tx-sender }
                { percentage: u10000 }  ;; 100% in basis points
            )
            
            ;; Increment counter
            (var-set content-counter content-id)
            
            ;; Return the content ID
            (ok content-id)
        )
    )
)

;; Add or update royalty split for a beneficiary
(define-public (set-royalty-split (content-id uint) (beneficiary principal) (percentage uint))
    (begin
        ;; Validate content-id
        (asserts! (is-valid-content-id content-id) (err ERR-INVALID-CONTENT-ID))
        
        ;; Validate beneficiary is not null
        (asserts! (not (is-eq beneficiary 'SP000000000000000000002Q6VF78)) (err ERR-INVALID-BENEFICIARY))
        
        (let 
            ((content (unwrap! (map-get? contents { content-id: content-id }) (err ERR-DOES-NOT-EXIST))))
            
            ;; Check authorization (only owner can set royalties)
            (asserts! (is-eq tx-sender (get owner content)) (err ERR-NOT-AUTHORIZED))
            
            ;; Validate percentage (must be between 0 and 10000 basis points)
            (asserts! (<= percentage u10000) (err ERR-INVALID-ROYALTY))
            
            ;; Set royalty split with validated inputs
            (map-set royalty-splits
                { content-id: content-id, beneficiary: beneficiary }
                { percentage: percentage }
            )
            
            (ok true)
        )
    )
)

;; Purchase a license for content
(define-public (purchase-license (content-id uint) (license-type (string-utf8 20)))
    (begin
        ;; Validate inputs
        (asserts! (is-valid-content-id content-id) (err ERR-INVALID-CONTENT-ID))
        (asserts! (is-valid-string license-type) (err ERR-INVALID-LICENSE-TYPE))
        
        (let 
            ((content (unwrap! (map-get? contents { content-id: content-id }) (err ERR-DOES-NOT-EXIST)))
             (price (get license-price content))
             (duration-days (get license-duration-days content))
             (owner (get owner content))
             (is-active (get is-active content))
             (expiration-height (+ block-height (* duration-days u144)))  ;; ~144 blocks per day
             (validated-license-type license-type))  ;; Using validated variable to satisfy compiler
            
            ;; Check that content is active
            (asserts! is-active (err ERR-INACTIVE))
            
            ;; Record the license with validated inputs
            (map-set licenses 
                { content-id: content-id, licensee: tx-sender }
                {
                    expiration: expiration-height,
                    license-type: validated-license-type,
                    payment-amount: price
                }
            )
            
            ;; Transfer STX payment from licensee to content owner
            (unwrap! (stx-transfer? price tx-sender owner) (err ERR-INSUFFICIENT-FUNDS))
            
            (ok true)
        )
    )
)

;; Distribute royalty payments for a content purchase
(define-public (distribute-royalties (content-id uint) (payment-amount uint))
    (begin
        ;; Validate content-id
        (asserts! (is-valid-content-id content-id) (err ERR-INVALID-CONTENT-ID))
        
        (let 
            ((content (unwrap! (map-get? contents { content-id: content-id }) (err ERR-DOES-NOT-EXIST))))
            
            ;; Check authorization (only creator can distribute royalties)
            (asserts! (is-eq tx-sender (get owner content)) (err ERR-NOT-AUTHORIZED))
            
            ;; Implementation would involve iterating through royalty splits and transferring 
            ;; proportional amounts to each beneficiary. However, Clarity doesn't support loops,
            ;; so this would need to be implemented with multiple individual transfers.
            ;; This is a simplified placeholder.
            
            (ok true)
        )
    )
)

;; Update content details
(define-public (update-content 
    (content-id uint) 
    (title (string-utf8 100)) 
    (description (string-utf8 500))
    (license-price uint)
    (license-duration-days uint)
    (is-active bool))
    
    (begin
        ;; Validate inputs
        (asserts! (is-valid-content-id content-id) (err ERR-INVALID-CONTENT-ID))
        (asserts! (is-valid-string title) (err ERR-INVALID-TITLE))
        (asserts! (is-valid-string description) (err ERR-INVALID-DESCRIPTION))
        (asserts! (> license-price u0) (err ERR-ZERO-PRICE))
        (asserts! (> license-duration-days u0) (err ERR-ZERO-DURATION))
        
        (let 
            ((content (unwrap! (map-get? contents { content-id: content-id }) (err ERR-DOES-NOT-EXIST)))
             (validated-title title)  ;; Using validated variables to satisfy compiler
             (validated-description description))
            
            ;; Check authorization (only owner can update)
            (asserts! (is-eq tx-sender (get owner content)) (err ERR-NOT-AUTHORIZED))
            
            ;; Update content details with validated inputs
            (map-set contents 
                { content-id: content-id }
                (merge content 
                    {
                        title: validated-title,
                        description: validated-description,
                        license-price: license-price,
                        license-duration-days: license-duration-days,
                        is-active: is-active
                    }
                )
            )
            
            (ok true)
        )
    )
)

;; Transfer content ownership
(define-public (transfer-content-ownership (content-id uint) (new-owner principal))
    (begin
        ;; Validate content-id
        (asserts! (is-valid-content-id content-id) (err ERR-INVALID-CONTENT-ID))
        
        ;; Validate new owner is not null
        (asserts! (not (is-eq new-owner 'SP000000000000000000002Q6VF78)) (err ERR-INVALID-BENEFICIARY))
        
        (let 
            ((content (unwrap! (map-get? contents { content-id: content-id }) (err ERR-DOES-NOT-EXIST))))
            
            ;; Check authorization (only owner can transfer)
            (asserts! (is-eq tx-sender (get owner content)) (err ERR-NOT-AUTHORIZED))
            
            ;; Update owner with validated inputs
            (map-set contents 
                { content-id: content-id }
                (merge content { owner: new-owner })
            )
            
            (ok true)
        )
    )
)