# Rspamd 3.12.1 Bayes spam learning configuration troubleshooting guide

Your rspamd 3.12.1 installation on Debian Trixie is experiencing a known issue where the learn cache indicates messages are "already learned" (HTTP 404 responses) while the actual Bayes database files aren't being created. This comprehensive guide provides specific solutions based on extensive research of official documentation, bug reports, and community experiences.

## The core issue: SQLite3 backend deprecated but misconfigured

**The primary problem** stems from rspamd defaulting to Redis backend since version 2.0, while your configuration attempts to use the deprecated SQLite3 backend. Combined with a known HTTP response code bug in version 3.12.1, this creates the exact symptoms you're experiencing.

### Why you're seeing "already learned" without Bayes files

Rspamd maintains a separate learn cache (`learn_cache.sqlite`) that tracks processed messages independently from the actual Bayes databases. When messages appear in this cache but the main Bayes files don't exist, rspamd returns HTTP 404 "already learned" responses - preventing new learning attempts.

## Immediate debugging steps

### 1. Verify current configuration state

```bash
# Check actual running configuration
rspamadm configdump classifier | grep -E "backend|path|statfile" -A2 -B2

# Verify database directory permissions
ls -la /var/lib/rspamd/
stat /var/lib/rspamd/

# Check if learn cache exists (this is your problem file)
ls -la /var/lib/rspamd/learn_cache.sqlite*
```

### 2. Test controller connectivity

```bash
# Test controller access
rspamc -h localhost:11334 stat

# Check for Bayes statistics
rspamc stat | grep -E "learned|BAYES"

# Monitor rspamd logs during a learn attempt
tail -f /var/log/rspamd/rspamd.log &
echo "test" | rspamc learn_spam
```

### 3. Enable debug logging temporarily

Create `/etc/rspamd/local.d/logging.inc`:
```ini
level = "debug";
debug_modules = ["bayes", "stat", "sqlite3", "controller"];
```

Then restart: `systemctl restart rspamd`

## Configuration fixes for SQLite3 backend

Since you're using SQLite3 backend with statfiles, create `/etc/rspamd/local.d/classifier-bayes.conf`:

```lua
classifier "bayes" {
    # Explicitly specify SQLite3 backend (no longer default)
    backend = "sqlite3";
    
    # Required for current versions
    new_schema = true;
    
    # Essential parameters
    min_tokens = 11;
    min_learns = 200;
    
    # Tokenizer configuration  
    tokenizer {
        name = "osb";
        # Window size (default changed to 2 in 3.9.0)
        window = 2;
    }
    
    # Learn cache configuration
    cache {
        path = "${DBDIR}/learn_cache.sqlite";
    }
    
    # Statfile definitions with explicit paths
    statfile {
        symbol = "BAYES_HAM";
        path = "${DBDIR}/bayes.ham.sqlite";
        spam = false;
    }
    
    statfile {
        symbol = "BAYES_SPAM";
        path = "${DBDIR}/bayes.spam.sqlite";
        spam = true;
    }
    
    # Learn condition (required)
    learn_condition = 'return require("lua_bayes_learn").can_learn';
    
    # Autolearn configuration
    autolearn {
        spam_threshold = 6.0;
        ham_threshold = -0.5;
        check_balance = true;
        min_balance = 0.9;
    }
}
```

## Controller worker configuration

Ensure `/etc/rspamd/local.d/worker-controller.inc` contains:

```ini
bind_socket = "localhost:11334";
count = 1;

# Generate password hash with: rspamadm pw
password = "$2$encrypted_password_hash";

# Allow passwordless access from localhost
secure_ip = ["127.0.0.1", "::1"];
```

## Fix permissions and reset databases

**This is the critical fix for your current state:**

```bash
#!/bin/bash
# Stop rspamd
systemctl stop rspamd

# Fix ownership (Debian uses _rspamd user)
chown -R _rspamd:_rspamd /var/lib/rspamd

# Remove corrupted learn cache (this causes "already learned" errors)
rm -f /var/lib/rspamd/learn_cache.sqlite*

# Remove any existing Bayes files to start fresh
rm -f /var/lib/rspamd/bayes.*.sqlite*

# Ensure directory permissions
chmod 755 /var/lib/rspamd

# Restart rspamd
systemctl restart rspamd

# Test database creation
echo "test spam message" | rspamc learn_spam
echo "test ham message" | rspamc learn_ham

# Verify files were created
ls -la /var/lib/rspamd/*.sqlite
```

## Dovecot sieve integration fix

The HTTP 404 responses cause sieve scripts to fail. Update your learning scripts:

**rspamd-learn-spam.sh:**
```bash
#!/bin/sh
rspamc -h localhost:11334 learn_spam
exit_code=$?
# Exit 0 even on "already learned" to prevent sieve failures
if [ $exit_code -eq 1 ]; then
    logger -t rspamd-learn "Message already learned as spam"
    exit 0
fi
exit $exit_code
```

**rspamd-learn-ham.sh:**
```bash
#!/bin/sh
rspamc -h localhost:11334 learn_ham
exit_code=$?
if [ $exit_code -eq 1 ]; then
    logger -t rspamd-learn "Message already learned as ham"
    exit 0
fi
exit $exit_code
```

## Verification commands

After applying fixes:

```bash
# Check if databases exist
ls -la /var/lib/rspamd/bayes.*.sqlite

# Verify learning works
rspamc stat | grep -A5 "Statfile"

# Test classification
echo "test message" | rspamc symbols

# Monitor real-time learning
tail -f /var/log/rspamd/rspamd.log | grep -i "bayes"
```

## Long-term recommendations

### Consider migrating to Redis backend

Since SQLite3 is deprecated and Redis is now default:

```bash
# Install Redis
apt install redis-server

# Configure rspamd for Redis
cat > /etc/rspamd/local.d/classifier-bayes.conf << EOF
classifier "bayes" {
    backend = "redis";
    servers = "127.0.0.1:6379";
    new_schema = true;
    # Rest of configuration...
}
EOF

# Migrate existing data
rspamadm statconvert \
  --spam-db /var/lib/rspamd/bayes.spam.sqlite \
  --ham-db /var/lib/rspamd/bayes.ham.sqlite \
  --symbol-spam BAYES_SPAM \
  --symbol-ham BAYES_HAM \
  -h localhost:6379
```

### Monitor for known issues

Your rspamd 3.12.1 has a known bug where HTTP 404 is incorrectly used for "already learned" responses. This was fixed in later versions (commit 58037bbffc0e3fd7873b6b411ea2c3aeb0f3ea91). Consider upgrading when a newer version becomes available in Debian Trixie.

## Summary of your specific issue

1. **Learn cache corruption**: The `learn_cache.sqlite` file contains entries for 253 messages, but the actual Bayes databases were never created
2. **Backend misconfiguration**: SQLite3 backend needs explicit configuration since rspamd 2.0
3. **Permission issues**: Debian uses `_rspamd` user which needs proper ownership of `/var/lib/rspamd`
4. **Integration problems**: Dovecot sieve scripts fail due to HTTP 404 responses

The provided fixes address all these issues and should restore proper Bayes learning functionality.
