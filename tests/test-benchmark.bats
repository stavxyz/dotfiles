#!/usr/bin/env bats
# Test: Performance Benchmark
# Description: Measure shell startup performance

setup() {
    export DOTFILES_DIR="/Users/stavxyz/dotfiles"
    export BENCHMARK_FILE="${HOME}/.cache/dotfiles/benchmark-results.txt"
    mkdir -p "$(dirname "$BENCHMARK_FILE")"
}

@test "measure shell startup time (10 runs)" {
    echo "=== Shell Startup Benchmark ===" > "$BENCHMARK_FILE"
    echo "Date: $(date)" >> "$BENCHMARK_FILE"
    echo "" >> "$BENCHMARK_FILE"

    TOTAL=0
    for i in {1..10}; do
        START=$(perl -MTime::HiRes -e 'printf("%.0f\n",Time::HiRes::time()*1000)')
        bash -l -c 'exit' 2>/dev/null
        END=$(perl -MTime::HiRes -e 'printf("%.0f\n",Time::HiRes::time()*1000)')
        ELAPSED=$((END - START))
        echo "Run $i: ${ELAPSED}ms" >> "$BENCHMARK_FILE"
        TOTAL=$((TOTAL + ELAPSED))
    done

    AVG=$((TOTAL / 10))
    echo "" >> "$BENCHMARK_FILE"
    echo "Average: ${AVG}ms" >> "$BENCHMARK_FILE"
    echo "Target: <500ms" >> "$BENCHMARK_FILE"

    # Output for test result
    echo "Average startup time: ${AVG}ms"

    # Test passes if startup is under 10 seconds (generous for baseline)
    # After optimization, this should be <500ms
    [ "$AVG" -lt 10000 ]
}

@test "completion loading is not blocking startup" {
    # If lazy loading is enabled, startup should be fast
    if bash -l -c 'echo "$DOTFILES_LAZY_COMPLETIONS"' 2>/dev/null | grep -q true; then
        START=$(perl -MTime::HiRes -e 'printf("%.0f\n",Time::HiRes::time()*1000)')
        bash -l -c 'exit' 2>/dev/null
        END=$(perl -MTime::HiRes -e 'printf("%.0f\n",Time::HiRes::time()*1000)')
        ELAPSED=$((END - START))

        # With lazy loading, should be <500ms
        echo "Lazy loading enabled, startup: ${ELAPSED}ms"
        [ "$ELAPSED" -lt 1000 ]
    else
        skip "Lazy loading not enabled yet"
    fi
}
