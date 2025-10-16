# Configuration Guide

The access-log-generator requires a YAML configuration file with specific required sections.

## Required Sections

### 1. `output` - Generator settings
```yaml
output:
  directory: ./logs          # Where to write log files
  rate: 1                    # Logs per second
  debug: false               # Enable debug output (default: false)
  pre_warm: false            # Simulate 24h before starting (default: true)
```

### 2. `state_transitions` - User behavior state machine
Defines probabilities for moving between states. Each state's probabilities must sum to 1.0.

**Required states:**
- `START` - Initial state
- `LOGIN` - Login process
- `DIRECT_ACCESS` - Skip login, go directly to content
- `BROWSING` - Viewing pages
- `LOGOUT` - Clean exit (transition to `END`)
- `ABANDON` - Session abandoned (transition to `END`)
- `ERROR` - Error encountered (transition to `END`)

**Example:**
```yaml
state_transitions:
  START:
    LOGIN: 0.7
    DIRECT_ACCESS: 0.3
  LOGIN:
    BROWSING: 0.9
    ABANDON: 0.1
  BROWSING:
    LOGOUT: 0.4
    ABANDON: 0.3
    ERROR: 0.05
    BROWSING: 0.25
  LOGOUT:
    END: 1.0
  ABANDON:
    END: 1.0
  ERROR:
    END: 1.0
```

### 3. `navigation` - Page routing patterns
Defines where users go from different states.

**Recognized keys:**
- `HOME` - Navigation from homepage/browsing (required)
- `LOGOUT` - Navigation when exiting (optional, defaults to HOME)

**Example:**
```yaml
navigation:
  HOME:
    "/": 0.2
    "/products": 0.5
    "/search": 0.3
  LOGOUT:
    "/": 1.0
```

### 4. `error_rates` - Error simulation
Controls error injection rates.

**Common keys:**
- `global_500` - Server error rate (0.0-1.0)
- `product_404` - Product not found rate
- `cart_abandon` - Shopping cart abandonment rate

**Example:**
```yaml
error_rates:
  global_500: 0.001        # 0.1% server errors
  product_404: 0.05        # 5% product pages not found
  cart_abandon: 0.3        # 30% abandon cart
```

### 5. `session` - Session behavior
Controls user session parameters.

```yaml
session:
  min_browsing_duration: 60      # Minimum session duration (seconds)
  max_browsing_duration: 600     # Maximum session duration (seconds)
  page_view_interval: 5          # Average time between page views (seconds)
```

### 6. `traffic_patterns` - Time-based traffic multipliers
Controls traffic rate variations throughout the day.

```yaml
traffic_patterns:
  - time: "0-6"         # Hours 0-6 (midnight to 6am)
    multiplier: 0.1     # 10% of base rate
  - time: "6-12"        # Hours 6-12 (morning)
    multiplier: 0.5     # 50% of base rate
  - time: "12-18"       # Hours 12-18 (afternoon)
    multiplier: 1.0     # 100% (peak)
  - time: "18-23"       # Hours 18-23 (evening)
    multiplier: 0.3     # 30% of base rate
```

**Note:** All 24 hours must be covered (0-23). Use `0-23: 1.0` for constant rate.

## Optional Sections

### `urls` - URL patterns (for reference, not actively used in generation)
### `user_agents` - Browser user agents
### `ip_ranges` - IP ranges for generating realistic IPs
### `search_terms` - Terms for search operations
### `product_categories` - Product types
### `profile_tabs` - User profile sections

## Common Errors

### `'str' object has no attribute 'get'`
Usually means:
- Missing required state transitions (e.g., no `END` states)
- `navigation` section has wrong keys (use `HOME` and `LOGOUT`, not custom names)
- Missing state transitions for required states

### `Missing required configuration sections`
Make sure you have ALL of:
- `output`
- `state_transitions`
- `navigation`
- `error_rates`
- `session`
- `traffic_patterns`

### `State transitions must sum to 1.0`
Each state's outgoing transitions must sum to exactly 1.0 (within 1% tolerance for float precision).

## Valid State Transitions

```
START → {LOGIN, DIRECT_ACCESS}
  ↓
LOGIN → {BROWSING, ABANDON}
  ↓
DIRECT_ACCESS → {BROWSING, ABANDON}
  ↓
BROWSING → {BROWSING, LOGOUT, ABANDON, ERROR}
  ↓
LOGOUT → END
ABANDON → END
ERROR → END
```

Terminal states (`END`) require `END: 1.0` transition.

## Example Full Configuration

See `access-logs/access-log-config.yaml` for a complete working example.

## Testing Your Config

Run with verbose mode to see detailed validation errors:
```bash
access-log-generator config.yaml --verbose
```
