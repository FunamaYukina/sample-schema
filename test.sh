#!/bin/bash

# Test script for validating database schemas
# Usage: ./test.sh [postgres|mysql|prisma|tbls|rails]

set -e

echo "Database Schema Test Runner"
echo "============================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

# Test PostgreSQL schema
test_postgres() {
    echo -e "\n${YELLOW}Testing PostgreSQL Schema...${NC}"
    
    if command -v psql &> /dev/null; then
        echo "PostgreSQL client found"
        
        # Check if schema file exists
        if [ -f "postgres/schema.sql" ]; then
            print_status 0 "Schema file exists"
            
            # Validate SQL syntax (dry run)
            echo "Validating SQL syntax..."
            psql -U postgres -d postgres -f postgres/schema.sql --set ON_ERROR_STOP=1 -v ON_ERROR_STOP=1 --single-transaction --dry-run 2>/dev/null
            print_status $? "SQL syntax validation"
        else
            print_status 1 "Schema file not found"
        fi
    else
        echo -e "${YELLOW}PostgreSQL client not installed, skipping...${NC}"
    fi
}

# Test MySQL schema
test_mysql() {
    echo -e "\n${YELLOW}Testing MySQL Schema...${NC}"
    
    if command -v mysql &> /dev/null; then
        echo "MySQL client found"
        
        if [ -f "mysql/schema.sql" ]; then
            print_status 0 "Schema file exists"
            
            # Basic syntax check
            echo "Checking SQL file syntax..."
            grep -q "CREATE TABLE" mysql/schema.sql
            print_status $? "Contains CREATE TABLE statements"
            
            grep -q "ENUM(" mysql/schema.sql
            print_status $? "Contains ENUM definitions"
        else
            print_status 1 "Schema file not found"
        fi
    else
        echo -e "${YELLOW}MySQL client not installed, skipping...${NC}"
    fi
}

# Test Prisma schema
test_prisma() {
    echo -e "\n${YELLOW}Testing Prisma Schema...${NC}"
    
    if [ -f "prisma/schema.prisma" ]; then
        print_status 0 "Schema file exists"
        
        # Check for enum definitions
        grep -q "enum " prisma/schema.prisma
        print_status $? "Contains enum definitions"
        
        # Check for model definitions
        grep -q "model " prisma/schema.prisma
        print_status $? "Contains model definitions"
        
        # If Prisma is installed, validate the schema
        if command -v npx &> /dev/null; then
            cd prisma
            if npx prisma validate 2>/dev/null; then
                print_status 0 "Prisma schema validation"
            else
                print_status 1 "Prisma schema validation"
            fi
            cd ..
        else
            echo -e "${YELLOW}Node/NPX not installed, skipping Prisma validation...${NC}"
        fi
    else
        print_status 1 "Schema file not found"
    fi
}

# Test tbls configuration
test_tbls() {
    echo -e "\n${YELLOW}Testing tbls Configuration...${NC}"
    
    if [ -f "tbls/.tbls.yml" ]; then
        print_status 0 "tbls config file exists"
    else
        print_status 1 "tbls config file not found"
    fi
    
    if [ -f "tbls/schema.sql" ]; then
        print_status 0 "Schema file exists"
        
        # Check for comments (important for tbls)
        grep -q "COMMENT ON" tbls/schema.sql
        print_status $? "Contains COMMENT statements for documentation"
    else
        print_status 1 "Schema file not found"
    fi
}

# Test Rails schema
test_rails() {
    echo -e "\n${YELLOW}Testing Rails Schema...${NC}"
    
    if [ -f "schemarb/schema.rb" ]; then
        print_status 0 "schema.rb file exists"
        
        # Check for Rails schema version
        grep -q "ActiveRecord::Schema" schemarb/schema.rb
        print_status $? "Valid Rails schema format"
        
        # Check for enum-related content
        grep -q "t.integer.*default:" schemarb/schema.rb
        print_status $? "Contains integer fields for enums"
    else
        print_status 1 "schema.rb file not found"
    fi
    
    if [ -f "schemarb/models_example.rb" ]; then
        print_status 0 "Model examples file exists"
        
        # Check for enum definitions in models
        grep -q "enum " schemarb/models_example.rb
        print_status $? "Contains enum definitions in models"
    else
        print_status 1 "Model examples file not found"
    fi
}

# Main execution
case "$1" in
    postgres)
        test_postgres
        ;;
    mysql)
        test_mysql
        ;;
    prisma)
        test_prisma
        ;;
    tbls)
        test_tbls
        ;;
    rails)
        test_rails
        ;;
    all|"")
        echo "Running all tests..."
        test_postgres
        test_mysql
        test_prisma
        test_tbls
        test_rails
        echo -e "\n${GREEN}All tests completed!${NC}"
        ;;
    *)
        echo "Usage: $0 [postgres|mysql|prisma|tbls|rails|all]"
        echo "  postgres - Test PostgreSQL schema"
        echo "  mysql    - Test MySQL schema"
        echo "  prisma   - Test Prisma schema"
        echo "  tbls     - Test tbls configuration"
        echo "  rails    - Test Rails schema"
        echo "  all      - Run all tests (default)"
        exit 1
        ;;
esac

echo -e "\n${YELLOW}Note:${NC} Some tests require the respective database clients to be installed."
echo "For full testing, ensure you have: psql, mysql, node/npm, and tbls installed."