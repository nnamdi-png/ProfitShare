;; Define the profit pool
(define-data-var profit-pool uint u0)

;; Define a map to store member allocations
(define-map member-allocations principal uint)

;; Define a list to keep track of all members
(define-data-var members (list 200 principal) (list))

;; Function to update the profit pool
(define-public (update-profit-pool (amount uint))
  (begin
    (var-set profit-pool (+ (var-get profit-pool) amount))
    (ok true)))

;; Function to calculate total allocations
(define-private (calculate-total-allocations)
  (fold + (map get-allocation (var-get members)) u0))

;; Helper function to get allocation value from principal
(define-private (get-allocation (member principal))
  (default-to u0 (map-get? member-allocations member)))

(define-public (set-member-allocation (member principal) (allocation uint))
  (let ((current-allocation (default-to u0 (map-get? member-allocations member))))
    (if (is-eq current-allocation allocation)
      (ok false)  ;; No change needed
      (begin
        (map-set member-allocations member allocation)
        (if (is-none (index-of (var-get members) member))
          (if (< (len (var-get members)) u200)
            (match (as-max-len? (append (var-get members) member) u200)
              updated-list (begin
                (var-set members updated-list)
                (ok true))
              (err u1))  ;; Error appending to list
            (err u2))  ;; List is full
          (ok true))))))

;; Function to distribute profits
(define-public (distribute-profits)
  (let ((current-pool (var-get profit-pool))
        (total-allocations (calculate-total-allocations))
        (sender-allocation (default-to u0 (map-get? member-allocations tx-sender))))
    (if (and (> total-allocations u0) (> sender-allocation u0))
      (let ((profit-amount (/ (* sender-allocation current-pool) total-allocations)))
        (begin
          (map-set member-allocations tx-sender (- sender-allocation profit-amount))
          (var-set profit-pool (- current-pool profit-amount))
          (ok profit-amount)))
      (err u0))))

;; Function to get the current profit pool amount
(define-read-only (get-profit-pool)
  (ok (var-get profit-pool)))

;; Function to get a member's current allocation
(define-read-only (get-member-allocation (member principal))
  (ok (default-to u0 (map-get? member-allocations member))))

;; Function to get all members
(define-read-only (get-members)
  (ok (var-get members)))