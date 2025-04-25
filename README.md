# ContentVault

A decentralized digital content licensing marketplace with automated royalty distribution built on Stacks blockchain.

## Overview

ContentVault empowers creators to monetize their digital content through a transparent licensing system. Built on the Stacks blockchain, it provides a trustless platform where creators can set their own terms, pricing, and royalty structures, while users can acquire verifiable licenses to content.

## Key Features

- **Content Registration**: Register any digital content with customizable licensing terms
- **Transparent Licensing**: Purchase time-bound licenses with clear usage rights
- **Royalty Distribution**: Automatically split payments among multiple beneficiaries
- **Usage Tracking**: Monitor how licensed content is being used
- **Revenue Analytics**: Track lifetime earnings and license metrics for each content piece

## Smart Contract Functions

### For Content Creators

| Function | Description |
|----------|-------------|
| `register-content` | Add new content to the marketplace with specified pricing and terms |
| `designate-beneficiaries` | Set up to 10 addresses to receive royalty payments |
| `get-content-metrics` | View performance data including total licenses sold and revenue |

### For Content Users

| Function | Description |
|----------|-------------|
| `acquire-license` | Purchase a license for specific content |
| `is-license-active` | Check if a license is still valid |
| `log-content-usage` | Record instances of content usage |

## How It Works

1. **Content Registration**
   ```clarity
   (register-content "My Digital Artwork" "image" u1000000 "Commercial use allowed with attribution" u20)
   ```
   This registers content with a license fee of 1 STX and 20% royalty rate.

2. **Setting Royalty Recipients**
   ```clarity
   (designate-beneficiaries u1 (list 'SP2CBQKJ78BXTPVJ2WWPHM7E97SF3VZTSQX7GPNF9 'SP1P72Z3704VMT3DMHPP2CB8TGQWGDBHD3RPR9GZS))
   ```
   Royalties will be evenly split between these recipients.

3. **License Acquisition**
   ```clarity
   (acquire-license u1)
   ```
   Users purchase a license by paying the fee, which is automatically distributed between the creator and royalty beneficiaries.

4. **License Verification**
   ```clarity
   (is-license-active u1)
   ```
   Verify if a license is currently valid before using content.

## Technical Implementation

ContentVault uses several data structures to manage the licensing ecosystem:

- **Content Registry**: Stores metadata about each piece of content
- **License Registry**: Tracks all issued licenses with their validity periods
- **Royalty Beneficiaries**: Maps content to lists of payment recipients

Licenses are valid for approximately one year (52,560 blocks at 10-minute block times) before requiring renewal.

## Use Cases

- **Digital Artists**: Sell licenses to artwork with royalties for derivative works
- **Musicians**: License music with customized usage rights
- **Writers**: Distribute written content with clear terms for republishing
- **Developers**: License code libraries with specific usage permissions
- **Photographers**: Sell photo usage rights with attribution requirements

## Getting Started

### For Creators

1. Register your content with appropriate title, media type, and pricing
2. Set up royalty beneficiaries if you want to share revenues
3. Share your content ID with potential licensees

### For Licensees

1. Find content you want to license and note the content ID
2. Review the license fee and terms of use
3. Call the `acquire-license` function with the content ID
4. Log usage appropriately according to the terms

## Future Development

- Customizable license durations
- Tiered licensing options (basic/premium)
- Content bundles and subscription models
- Integration with decentralized storage solutions
- Secondary marketplace for license transfers

## Security Considerations

The contract has been designed with security best practices in mind:
- Principal-based access control for content management
- Transaction verification for all financial operations
- Clear error codes for troubleshooting

## Contributing

ContentVault is open for community contributions. To contribute:
1. Review the existing contract functionality
2. Submit proposals for enhancements or bug fixes
3. Test thoroughly before submitting changes
