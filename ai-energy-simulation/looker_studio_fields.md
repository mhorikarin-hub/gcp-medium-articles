# Looker Studio Custom Fields (Energy Simulation)

This document stores the custom formulas used in Looker Studio to enhance the Energy Simulation dashboard.

## 📍 Dynamic Google Maps Link

Creates a clickable hyperlink in Looker Studio tables to inspect the specific property location directly on Google Maps.

- **Formula Type**: Calculated Field
- **Field Name**: `View on Map`

### Formula:
```text
HYPERLINK(
  CONCAT(
    "[http://maps.google.com/maps?q=](http://maps.google.com/maps?q=)", 
    ADDRESS1, 
    ",", 
    POSTCODE
  ),
  "View on Map"
)
