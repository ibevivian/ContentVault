;; ContentVault: Digital Content Licensing Platform
;; A decentralized marketplace for licensing digital content with royalty distribution

;; Define the content registry
(define-data-var global-content-id-counter uint u0)

(define-map content-registry
  { content-id: uint }
  {
    creator: principal,
    title: (string-ascii 50),
    media-type: (string-ascii 10),
    license-fee: uint,
    terms-of-use: (string-ascii 200),
    royalty-percentage: uint,
    lifetime-revenue: uint
  }
)

;; Define the license registry
(define-map license-registry
  { license-id: uint }
  {
    content-id: uint,
    licensee: principal,
    expiration-block: uint,
    usage-counter: uint
  }
)

;; Define royalty beneficiaries
(define-map royalty-beneficiaries
  { content-id: uint }
  { beneficiary-list: (list 10 principal) }
)

;; Function to register new content
(define-public (register-content (title (string-ascii 50)) (media-type (string-ascii 10)) (license-fee uint) (terms-of-use (string-ascii 200)) (royalty-percentage uint))
  (let
    (
      (new-content-id (+ (var-get global-content-id-counter) u1))
    )
    (map-set content-registry
      { content-id: new-content-id }
      {
        creator: tx-sender,
        title: title,
        media-type: media-type,
        license-fee: license-fee,
        terms-of-use: terms-of-use,
        royalty-percentage: royalty-percentage,
        lifetime-revenue: u0
      }
    )
    (var-set global-content-id-counter new-content-id)
    (ok new-content-id)
  )
)


;; Function to designate royalty beneficiaries
(define-public (designate-beneficiaries (content-id uint) (beneficiary-list (list 10 principal)))
  (let
    (
      (content-details (unwrap! (map-get? content-registry { content-id: content-id }) (err u404)))
    )
    (asserts! (is-eq tx-sender (get creator content-details)) (err u403))
    (ok (map-set royalty-beneficiaries { content-id: content-id } { beneficiary-list: beneficiary-list }))
  )
)

;; Function to acquire a license
(define-public (acquire-license (content-id uint))
  (let
    (
      (content-details (unwrap! (map-get? content-registry { content-id: content-id }) (err u404)))
      (license-fee (get license-fee content-details))
      (royalty-percentage (get royalty-percentage content-details))
      (content-creator (get creator content-details))
      (royalty-payment (/ (* license-fee royalty-percentage) u100))
      (creator-payment (- license-fee royalty-payment))
    )
    (if (is-eq tx-sender content-creator)
      (err u403)
      (match (stx-transfer? license-fee tx-sender (as-contract tx-sender))
        success
          (let
            (
              (new-license-id (+ (var-get global-content-id-counter) u1))
            )
            (try! (distribute-royalty-payments content-id royalty-payment))
            (try! (stx-transfer? creator-payment (as-contract tx-sender) content-creator))
            (map-set license-registry
              { license-id: new-license-id }
              {
                content-id: content-id,
                licensee: tx-sender,
                expiration-block: (+ block-height u52560), ;; License valid for ~1 year (assuming 10-minute blocks)
                usage-counter: u0
              }
            )
            (map-set content-registry
              { content-id: content-id }
              (merge content-details { lifetime-revenue: (+ (get lifetime-revenue content-details) license-fee) })
            )
            (var-set global-content-id-counter new-license-id)
            (ok new-license-id)
          )
        error (err error)
      )
    )
  )
)