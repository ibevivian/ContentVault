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
