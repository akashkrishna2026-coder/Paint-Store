#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

OUT_DIR="$(dirname "$0")"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_DIR="$OUT_DIR/reports/$TIMESTAMP"

# Create report directory
mkdir -p "$REPORT_DIR"

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}    Flutter Integration Test Report Generator  ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Report directory:${NC} $REPORT_DIR"
echo ""

# Set timeout to prevent hanging
export TIMEOUT_DURATION=300
export JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-amd64

# Build optional --dart-define flags for env-driven auth test
DEFINE_ARGS=""
if [ -n "${TEST_EMAIL:-}" ]; then
  DEFINE_ARGS+=" --dart-define=TEST_EMAIL=${TEST_EMAIL}"
fi
if [ -n "${TEST_PASSWORD:-}" ]; then
  DEFINE_ARGS+=" --dart-define=TEST_PASSWORD=${TEST_PASSWORD}"
fi

if [ -z "$DEFINE_ARGS" ]; then
  echo -e "${YELLOW}⚠ TEST_EMAIL/TEST_PASSWORD not set; env-driven auth test may be skipped.${NC}"
else
  echo -e "${BLUE}Using dart-defines:${NC} ${DEFINE_ARGS}"
fi

# Run tests with multiple report formats
echo -e "${BLUE}[1/4]${NC} Running tests with JSON output..."
if timeout ${TIMEOUT_DURATION}s flutter test ${DEFINE_ARGS} integration_test/ -r json > "$REPORT_DIR/report.json" 2>&1; then
    echo -e "${GREEN}✓ JSON report generated${NC}"
else
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 124 ]; then
        echo -e "${RED}✗ Tests timed out after ${TIMEOUT_DURATION}s${NC}"
        echo '{"error": "Test execution timed out"}' > "$REPORT_DIR/report.json"
    else
        echo -e "${YELLOW}⚠ Tests completed with errors (exit code: $EXIT_CODE)${NC}"
    fi
fi

echo -e "${BLUE}[2/4]${NC} Running tests with expanded output..."
if timeout ${TIMEOUT_DURATION}s flutter test ${DEFINE_ARGS} integration_test/ -r expanded > "$REPORT_DIR/report.txt" 2>&1; then
    echo -e "${GREEN}✓ Text report generated${NC}"
else
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 124 ]; then
        echo -e "${RED}✗ Tests timed out${NC}"
    fi
fi

# Generate JUnit XML if tojunit is available
echo -e "${BLUE}[3/4]${NC} Generating JUnit XML report..."
if command -v tojunit >/dev/null 2>&1; then
    if cat "$REPORT_DIR/report.txt" | tojunit > "$REPORT_DIR/junit.xml" 2>/dev/null; then
        echo -e "${GREEN}✓ JUnit XML report generated${NC}"
    else
        echo -e "${YELLOW}⚠ JUnit conversion failed${NC}"
    fi
else
    echo -e "${YELLOW}⚠ 'tojunit' not installed. Install with: dart pub global activate junitreport${NC}"
fi

# Generate HTML summary
echo -e "${BLUE}[4/4]${NC} Generating HTML summary..."
cat > "$REPORT_DIR/report.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Integration Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 3px solid #4CAF50; padding-bottom: 10px; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin: 20px 0; }
        .card { background: #fff; padding: 15px; border-radius: 8px; border-left: 4px solid #4CAF50; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
        .card.failed { border-left-color: #f44336; }
        .card.skipped { border-left-color: #ff9800; }
        .card h3 { margin: 0 0 10px 0; color: #666; font-size: 14px; }
        .card .value { font-size: 32px; font-weight: bold; color: #333; }
        pre { background: #f5f5f5; padding: 15px; border-radius: 4px; overflow-x: auto; }
        .timestamp { color: #888; font-size: 14px; }
        .status-passed { color: #4CAF50; font-weight: bold; }
        .status-failed { color: #f44336; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🧪 Integration Test Report</h1>
        <p class="timestamp">Generated: TIMESTAMP_PLACEHOLDER</p>
        
        <div class="summary">
            <div class="card">
                <h3>✅ Passed</h3>
                <div class="value" id="passed">-</div>
            </div>
            <div class="card failed">
                <h3>❌ Failed</h3>
                <div class="value" id="failed">-</div>
            </div>
            <div class="card skipped">
                <h3>⏭️ Skipped</h3>
                <div class="value" id="skipped">-</div>
            </div>
        </div>
        
        <h2>📊 Test Output</h2>
        <pre id="output">Loading...</pre>
        
        <h2>📄 Available Reports</h2>
        <ul>
            <li><a href="report.json">JSON Report</a></li>
            <li><a href="report.txt">Text Report</a></li>
            <li><a href="junit.xml">JUnit XML</a> (if available)</li>
        </ul>
    </div>
    
    <script>
        // Parse report.txt and extract test results
        fetch('report.txt')
            .then(r => r.text())
            .then(text => {
                document.getElementById('output').textContent = text;
                
                // Extract test counts from output
                const passMatch = text.match(/\+(\d+)/);
                const failMatch = text.match(/-(\d+)/);
                const skipMatch = text.match(/~(\d+)/);
                
                if (passMatch) document.getElementById('passed').textContent = passMatch[1];
                if (failMatch) document.getElementById('failed').textContent = failMatch[1];
                if (skipMatch) document.getElementById('skipped').textContent = skipMatch[1];
            })
            .catch(err => {
                document.getElementById('output').textContent = 'Error loading test output';
            });
    </script>
</body>
</html>
EOF

# Replace timestamp placeholder
sed -i "s/TIMESTAMP_PLACEHOLDER/$(date '+%Y-%m-%d %H:%M:%S')/" "$REPORT_DIR/report.html"
echo -e "${GREEN}✓ HTML report generated${NC}"

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Test execution completed!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Reports generated in:${NC}"
echo -e "  📁 $REPORT_DIR"
echo ""
echo -e "${YELLOW}Available files:${NC}"
ls -lh "$REPORT_DIR" | tail -n +2 | awk '{printf "  📄 %-20s %5s\n", $9, $5}'
echo ""
echo -e "${BLUE}View HTML report:${NC}"
echo -e "  xdg-open $REPORT_DIR/report.html"
echo ""

# Create symlink to latest report
ln -sfn "$REPORT_DIR" "$OUT_DIR/latest"
echo -e "${GREEN}✓ Latest report available at: $OUT_DIR/latest/${NC}"
