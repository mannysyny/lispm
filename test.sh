#!/bin/bash

TARGET_TRIPLE=$(lli -version | grep 'Default target' | sed 's/.*: \(.*\)/\1/')

TESTS=0
FAILURES=0

FAILURE_OUT=""

test_subsystem() {
    SUBSYSTEM=$1
    for TEST_FILE in $(ls tests/${SUBSYSTEM}/test-*.llisp); do
        TESTS=$(($TESTS + 1))
        DIFF=$(lli -mtriple="$TARGET_TRIPLE" test-${SUBSYSTEM}.bc $TEST_FILE | diff -u $TEST_FILE.out -)
        if [ $? == 0 ]
        then
            echo -n "."
        else
            FAILURES=$(($FAILURES + 1))
            FAILURE_OUT="${FAILURE_OUT}\nFailure in ${TEST_FILE}:\n\n${DIFF}\n"
            echo -n "F"
        fi
    done
}

for SUBSYSTEM in $(ls tests); do
    if [ -d "tests/$SUBSYSTEM" ]
    then
        test_subsystem $SUBSYSTEM
    else
        echo "Not a subsystem $SUBSYSTEM"
    fi
done

if [ $FAILURES == 0 ]
then
    echo -e "\nSuccess!"
else
    echo -e "\n"
    printf "${FAILURE_OUT}"
    echo -e "\n${FAILURES} of ${TESTS} Tests Failed"

    exit 1
fi

echo -e "\nRan ${TESTS} tests"
