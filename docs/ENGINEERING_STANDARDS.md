# Engineering Standards

> **Philosophy**: Write code that is a joy to read, trivial to test, and easy to extend.

This document defines our organizational engineering standards. These principles apply to all projects and guide every technical decision we make.

> **Note for AI Assistants**: This is the comprehensive human-facing version. For a concise, actionable AI-optimized version, see `.claude/docs/ENGINEERING_STANDARDS.md`. Both versions are intentionally maintained with different audiences in mind.

---

## Table of Contents

1. [Core Principles](#core-principles)
2. [Python Best Practices](#python-best-practices)
3. [Code Style Guidelines](#code-style-guidelines)
4. [Architecture Patterns](#architecture-patterns)
5. [Testing Requirements](#testing-requirements)
6. [Development Workflow](#development-workflow)
7. [Documentation Standards](#documentation-standards)
8. [Code Quality Tools](#code-quality-tools)

---

## Core Principles

### 1. Simple > Complex

**Choose straightforward solutions over clever ones.**

```python
# BAD: Clever but hard to understand
result = reduce(lambda a,b: a+b, filter(lambda x: x%2, map(int, data.split())))

# GOOD: Explicit and clear
numbers = [int(x) for x in data.split()]
odd_numbers = [n for n in numbers if n % 2 == 1]
result = sum(odd_numbers)
```

**Why**: Code is read far more often than it's written. Clarity trumps cleverness.

### 2. Explicit > Implicit

**Make your intentions clear. No magic, no surprises.**

```python
# BAD: Implicit behavior
def process_data(df, mode=1):
    if mode == 1:
        # ... (what does mode 1 do?)
    elif mode == 2:
        # ... (what about mode 2?)

# GOOD: Explicit intent
from enum import Enum

class ProcessingMode(Enum):
    NORMALIZE = "normalize"
    VALIDATE = "validate"
    TRANSFORM = "transform"

def process_data(df: pd.DataFrame, mode: ProcessingMode) -> pd.DataFrame:
    """Process dataframe based on specified mode."""
    match mode:
        case ProcessingMode.NORMALIZE:
            return normalize_columns(df)
        case ProcessingMode.VALIDATE:
            return validate_schema(df)
        case ProcessingMode.TRANSFORM:
            return apply_transformations(df)
```

### 3. DRY (Don't Repeat Yourself)

**Every piece of knowledge should have a single, authoritative representation.**

```python
# BAD: Logic duplicated
def process_user_input(text):
    return text.strip().lower().replace('_', '-')

def process_file_name(filename):
    return filename.strip().lower().replace('_', '-')

def process_tag(tag):
    return tag.strip().lower().replace('_', '-')

# GOOD: Single source of truth
def normalize_identifier(text: str) -> str:
    """Normalize text: strip, lowercase, replace underscores."""
    return text.strip().lower().replace('_', '-')

# Use everywhere
user_input = normalize_identifier(raw_input)
filename = normalize_identifier(raw_filename)
tag = normalize_identifier(raw_tag)
```

### 4. Convention Over Configuration

**Sensible defaults that work out of the box. Configuration only when necessary.**

```python
# BAD: Everything requires configuration
processor = DataProcessor(
    encoding='utf-8',
    date_format='%Y-%m-%d',
    decimal_separator='.',
    trim_whitespace=True,
    log_level='INFO'
)

# GOOD: Smart defaults, configure only exceptions
processor = DataProcessor()  # Works immediately
processor_eu = DataProcessor(decimal_separator=',')  # Override when needed
```

### 5. Fail Fast

**Detect errors early and fail immediately with clear messages.**

```python
# BAD: Silent failures or late errors
def process_file(path):
    try:
        data = load_file(path)
        return process_data(data)
    except:
        return None  # What went wrong?

# GOOD: Explicit validation, clear errors
def process_file(path: Path) -> ProcessedData:
    """Process file at path. Raises ValueError if file invalid."""
    if not path.exists():
        raise FileNotFoundError(f"File not found: {path}")

    if not path.suffix == '.xlsx':
        raise ValueError(f"Expected .xlsx file, got: {path.suffix}")

    if path.stat().st_size > 100_000_000:  # 100MB
        raise ValueError(f"File too large (>100MB): {path}")

    return process_data(load_file(path))
```

### 6. YAGNI (You Aren't Gonna Need It)

**Don't build features until you actually need them.**

```python
# BAD: Over-engineering for imaginary future
class DataProcessor:
    def process(
        self,
        data,
        strategy='default',
        use_ml=False,  # ML not implemented yet
        cache=True,     # No cache exists yet
        parallel=False, # Not needed yet
        retry_count=3,  # Haven't hit failures yet
        timeout=30      # No timeouts observed yet
    ):
        ...

# GOOD: Build what you need now
class DataProcessor:
    def process(self, data: pd.DataFrame) -> pd.DataFrame:
        """Process dataframe using current validated approach."""
        return self._apply_transformations(data)

# Add features later when:
# - ML: When we have training data and proof it helps
# - Caching: When profiling shows it's a bottleneck
# - Parallelization: When single-threaded is too slow
```

### 7. File Size Limit: 500 Lines

**If a file exceeds 500 lines, it's doing too much. Split it.**

**Strategies**:
- Extract helper functions to utilities
- Split large classes into smaller, focused classes
- Move constants to configuration files
- Use composition over inheritance
- Create submodules when a module grows

```python
# If models/participant.py grows too large:
models/participant/
├── __init__.py         # Re-export main classes
├── participant.py      # Core Participant model (< 500 lines)
├── matching.py         # Matching-related methods
└── validation.py       # Validation logic
```

---

## Python Best Practices

### ⚠️ CRITICAL: Virtual Environments - ALWAYS Required

**ALWAYS use virtual environments. NEVER modify or install packages to system/global Python. No exceptions.**

This is a non-negotiable organizational standard that applies to:
- ✅ All Python development work
- ✅ Running scripts or tools
- ✅ Installing any Python packages
- ✅ Humans and AI assistants alike

**PROHIBITED: Global Package Installation**
```bash
# ❌ NEVER DO THIS - Modifies system Python
pip install click
python3 -m pip install --user rich
sudo pip install anything

# These commands are BANNED in our organization
```

**REQUIRED: Virtual Environment Usage**
```bash
# ✅ ALWAYS DO THIS - Isolated, safe, reproducible
python3 -m venv .venv
source .venv/bin/activate  # macOS/Linux
.venv\Scripts\activate     # Windows

# Now safe to install
pip install -r requirements.txt

# Verify you're in venv
which python  # Should show .venv/bin/python
python --version

# Deactivate when done
deactivate
```

**Why Virtual Environments**:
- ✅ Dependency isolation - no conflicts between projects
- ✅ Reproducibility - everyone uses same package versions
- ✅ Protects user's system Python from corruption
- ✅ Easy cleanup - delete `.venv/` to start fresh
- ✅ Required by modern Python - PEP 668 externally-managed-environment
- ✅ Prevents "functions on my machine" issues

**For AI Assistants**:
- **NEVER** run `pip install` without first verifying a virtual environment is active
- **NEVER** use `--user` flag or `sudo pip`
- **ALWAYS** check `which python` shows `.venv/bin/python` before installing packages
- **ALWAYS** use `.venv/bin/python` explicitly when running Python commands
- If no virtual environment exists, create one first, then activate it, then install

### Modern Python Packaging

Use `pyproject.toml` (PEP 621) for dependency management:

```toml
[project]
name = "my-project"
version = "0.1.0"
description = "Project description"
requires-python = ">=3.11"
dependencies = [
    "pandas>=2.0.0",
    "pydantic>=2.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "pytest-cov>=4.0.0",
    "ruff>=0.1.0",
    "mypy>=1.5.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

Install in editable mode:
```bash
pip install -e ".[dev]"
```

### Type Hints - Required

**All functions must have type hints.**

```python
from typing import Protocol
from datetime import date
from pathlib import Path
import pandas as pd

# Type aliases for clarity
UserID = str
ConfidenceLevel = Literal['HIGH', 'MEDIUM', 'LOW']

# Function signatures with types
def process_data(
    data: pd.DataFrame,
    user_id: UserID,
    threshold: float = 0.8
) -> tuple[pd.DataFrame, list[str]]:
    """
    Process dataframe for user.

    Returns:
        Tuple of (processed_data, errors)
    """
    ...

# Data classes with types
@dataclass
class User:
    id: UserID
    name: str
    email: str
    created_at: date
    is_active: bool = True

# Protocols for interfaces (duck typing with type checking)
class Processor(Protocol):
    """Interface for data processors."""

    def process(self, data: pd.DataFrame) -> pd.DataFrame:
        """Process dataframe and return result."""
        ...
```

**Benefits**:
- IDE autocomplete and inline documentation
- Catch errors before runtime (mypy in CI/CD)
- Self-documenting code
- Easier refactoring

### Error Handling - Explicit Only

**Only catch exceptions you expect and can handle.**

```python
# BAD: Catching everything hides bugs
def get_value(data, key):
    try:
        return data[key]
    except:  # Catches typos in YOUR code too!
        return None

# BAD: Catching exceptions you don't expect
def parse_file(path):
    try:
        df = pd.read_excel(path)
        return process_dataframe(df)
    except Exception as e:  # What exception? We don't know!
        logger.error(f"Something went wrong: {e}")
        return None

# GOOD: Explicit checks, no exception handling needed
def get_value(data: dict, key: str) -> str:
    if key not in data:
        raise KeyError(f"Required key '{key}' not found. Available: {list(data.keys())}")
    return data[key]

# GOOD: Only catch specific, expected exceptions
def parse_file(path: Path) -> pd.DataFrame:
    if not path.exists():
        raise FileNotFoundError(f"File not found: {path}")

    # We KNOW BadZipFile can happen with corrupt Excel files
    try:
        df = pd.read_excel(path)
    except BadZipFile as e:
        raise ValueError(f"Corrupt Excel file: {path}") from e

    # Let other exceptions bubble up - we don't expect them
    return process_dataframe(df)
```

**When to Use Try/Except**:
- ✅ File operations (FileNotFoundError expected)
- ✅ External API calls (network errors expected)
- ✅ Parsing user input (ValueError expected)
- ❌ Regular Python logic (if catching IndexError, your code has a bug)
- ❌ "Just in case" (if you don't know what exception could occur, don't catch it)

### Logging - Structured and Contextual

**Always use structured logging. Never use `print()`.**

```python
import structlog

logger = structlog.get_logger()

def process_batch(batch_id: str, items: list[Item]) -> BatchResult:
    logger.info(
        "batch_processing_started",
        batch_id=batch_id,
        item_count=len(items)
    )

    results = []
    errors = []

    for item in items:
        try:
            result = process_item(item)
            results.append(result)
            logger.debug(
                "item_processed",
                batch_id=batch_id,
                item_id=item.id,
                status="success"
            )
        except ValidationError as e:
            errors.append((item.id, str(e)))
            logger.warning(
                "item_validation_failed",
                batch_id=batch_id,
                item_id=item.id,
                error=str(e)
            )

    logger.info(
        "batch_processing_completed",
        batch_id=batch_id,
        success_count=len(results),
        error_count=len(errors)
    )

    return BatchResult(results, errors)
```

**Benefits**:
- Structured data for easy querying (JSON logs)
- Consistent format across codebase
- Easy to aggregate and analyze
- Context preserved (batch_id, item_id, etc.)

---

## Code Style Guidelines

### Python Style

- **Line length**: 100 characters max
- **Formatter**: Ruff (replaces Black, isort, etc.)
- **Type checker**: mypy with `--strict`
- **Docstrings**: Google-style for all public functions and classes

### Concise and Elegant Code

**Every line should earn its place.**

```python
# BAD: Verbose and unclear
def get_full_name(first_name, middle_name, last_name):
    if middle_name is not None and middle_name != '':
        full_name = first_name + ' ' + middle_name + ' ' + last_name
    else:
        full_name = first_name + ' ' + last_name
    return full_name

# GOOD: Pythonic with filter
def get_full_name(first: str, middle: str | None, last: str) -> str:
    """Return full name, including middle if present."""
    return ' '.join(filter(None, [first, middle, last]))
```

**Guidelines**:
- Prefer comprehensions over loops when clearer
- Use built-in functions (`filter`, `map`, `any`, `all`)
- Avoid deep nesting (max 3 levels)
- Extract complex conditions into named variables
- One logical operation per line

**Example - List Comprehension**:
```python
# BAD
high_confidence_items = []
for item in items:
    if item.confidence == 'HIGH':
        high_confidence_items.append(item)

# GOOD
high_confidence_items = [item for item in items if item.confidence == 'HIGH']
```

### Naming Conventions

```python
# Constants - UPPER_SNAKE_CASE
MAX_RETRY_COUNT = 3
DEFAULT_TIMEOUT_SECONDS = 30

# Functions and variables - snake_case
def calculate_total_price(items: list[Item]) -> Decimal:
    total_price = sum(item.price for item in items)
    return total_price

# Classes - PascalCase
class DataProcessor:
    pass

class UserAccount:
    pass

# Private methods/attributes - leading underscore
class MyClass:
    def _internal_helper(self):
        pass

    def public_method(self):
        self._internal_helper()

# Type aliases - PascalCase
UserID = str
ProcessingMode = Literal['FAST', 'THOROUGH']
```

---

## Architecture Patterns

### Separation of Concerns

**Each module, class, and function should have one clear responsibility.**

```
src/myproject/
├── parsers/           # Read and parse files
│   ├── excel_parser.py
│   ├── csv_parser.py
│   └── base_parser.py
├── validators/        # Validate data quality
│   ├── schema_validator.py
│   └── business_rules.py
├── processors/        # Transform and process data
│   ├── normalizer.py
│   └── aggregator.py
├── exporters/         # Export to various formats
│   └── excel_exporter.py
├── models/            # Data models (Pydantic)
│   ├── user.py
│   └── transaction.py
├── services/          # Business logic orchestration
│   └── processing_service.py
├── config/            # Configuration loading
│   └── settings.py
└── utils/             # Shared utilities
    ├── date_utils.py
    └── text_utils.py
```

**Each function does ONE thing**:
```python
def read_excel_file(path: Path) -> pd.DataFrame:
    """Read Excel file and return raw DataFrame."""
    # Only file I/O, no parsing logic

def detect_header_row(df: pd.DataFrame) -> int:
    """Find the row number where headers start."""
    # Only header detection, no data extraction

def extract_data_rows(df: pd.DataFrame, header_row: int) -> pd.DataFrame:
    """Extract data rows after header."""
    # Only data extraction, no normalization

def normalize_column_names(df: pd.DataFrame, mapping: dict) -> pd.DataFrame:
    """Standardize column names using mapping."""
    # Only column renaming, no data transformation
```

### Dependency Injection

**Don't create dependencies inside; inject them from outside.**

```python
# BAD: Hard-coded dependencies
class ProcessingService:
    def __init__(self):
        self.parser = DataParser()  # Can't swap implementations
        self.validator = DataValidator()

# GOOD: Dependencies injected
class ProcessingService:
    def __init__(
        self,
        parser: DataParser,
        validator: DataValidator,
    ):
        self.parser = parser
        self.validator = validator

# Easy to test with mocks
def test_processing_service():
    mock_parser = Mock(spec=DataParser)
    mock_validator = Mock(spec=DataValidator)
    service = ProcessingService(mock_parser, mock_validator)
    # Test service behavior with controlled dependencies
```

**Benefits**:
- Makes testing trivial (inject mocks)
- Easy to swap implementations
- Dependencies are explicit and clear

### Composition Over Inheritance

**Build complex behavior by combining simple objects, not deep inheritance.**

```python
# BAD: Deep inheritance hierarchy
class BaseParser:
    def parse(self): ...

class ExcelParser(BaseParser):
    def read_excel(self): ...

class SpecializedParser(ExcelParser):
    def parse_specialized(self): ...

class SpecializedValidatingParser(SpecializedParser):
    def validate(self): ...

# GOOD: Composition
class ExcelReader:
    def read(self, path: Path) -> pd.DataFrame: ...

class ColumnMapper:
    def map_columns(self, df: pd.DataFrame, mapping: dict) -> pd.DataFrame: ...

class DataValidator:
    def validate(self, df: pd.DataFrame) -> list[str]: ...

class SpecializedParser:
    def __init__(
        self,
        reader: ExcelReader,
        mapper: ColumnMapper,
        validator: DataValidator
    ):
        self.reader = reader
        self.mapper = mapper
        self.validator = validator

    def parse(self, path: Path) -> pd.DataFrame:
        df = self.reader.read(path)
        df = self.mapper.map_columns(df, SPECIALIZED_MAPPING)
        errors = self.validator.validate(df)
        if errors:
            raise ValidationError(errors)
        return df
```

### Immutability Where Possible

**Prefer immutable data structures to reduce bugs.**

```python
# Immutable data classes
@dataclass(frozen=True)  # Immutable
class User:
    id: str
    name: str
    email: str

# Pure functions (no side effects)
def normalize_name(name: str) -> str:
    """Return normalized name without modifying input."""
    return name.strip().upper()

# Return new DataFrame instead of mutating
def add_calculated_column(df: pd.DataFrame) -> pd.DataFrame:
    """Return new DataFrame with calculated column added."""
    return df.assign(
        total_price=df['quantity'] * df['unit_price']
    )
```

### Interface Segregation (Protocols)

**Keep interfaces focused. Clients shouldn't depend on methods they don't use.**

```python
from typing import Protocol

# BAD: Fat interface
class DataProcessor(Protocol):
    def parse(self, path: Path): ...
    def validate(self, df: pd.DataFrame): ...
    def normalize(self, df: pd.DataFrame): ...
    def export(self, df: pd.DataFrame, path: Path): ...
    # User must implement ALL methods even if they only need parse()

# GOOD: Focused interfaces
class Parseable(Protocol):
    def parse(self, path: Path) -> pd.DataFrame: ...

class Validatable(Protocol):
    def validate(self, df: pd.DataFrame) -> list[str]: ...

class Exportable(Protocol):
    def export(self, df: pd.DataFrame, path: Path) -> None: ...

# Implement only what you need
class MyParser:
    def parse(self, path: Path) -> pd.DataFrame:
        return pd.read_excel(path)
    # Don't need validate or export
```

**Protocols vs Abstract Base Classes**:
- Protocols: Structural typing (duck typing with type checking)
- No inheritance needed - just implement the methods
- More flexible and Pythonic

```python
# With Protocol - no inheritance needed
class Processor(Protocol):
    def process(self, data: pd.DataFrame) -> pd.DataFrame: ...

class MyProcessor:  # No inheritance!
    def process(self, data: pd.DataFrame) -> pd.DataFrame:
        return data * 2

# MyProcessor matches the Processor protocol automatically!
def run_processor(processor: Processor, data: pd.DataFrame):
    return processor.process(data)

run_processor(MyProcessor(), df)  # ✅ Works - type checker validates
```

---

## Testing Requirements

### Test Structure

```
tests/
├── __init__.py
├── conftest.py         # Pytest fixtures
├── unit/               # Unit tests mirror src structure
│   ├── test_parsers.py
│   └── test_validators.py
├── integration/        # Integration tests
│   └── test_workflows.py
└── fixtures/           # Test data
    └── sample_data.xlsx
```

### Test Types

1. **Unit Tests** (`tests/unit/`) - Fast, isolated, mocked dependencies
2. **Integration Tests** (`tests/integration/`) - Multi-component workflows
3. **E2E Tests** (`tests/e2e/`) - Full system with real external services

### Unit Test Example

```python
import pytest
from unittest.mock import Mock
from myproject.services import ProcessingService

@pytest.fixture
def mock_parser():
    """Mock parser that returns sample data."""
    parser = Mock()
    parser.parse.return_value = pd.DataFrame({
        'name': ['Alice', 'Bob'],
        'age': [30, 25]
    })
    return parser

@pytest.fixture
def mock_validator():
    """Mock validator that always passes."""
    validator = Mock()
    validator.validate.return_value = []  # No errors
    return validator

def test_processing_service_success(mock_parser, mock_validator):
    """Test processing service with valid data."""
    service = ProcessingService(mock_parser, mock_validator)

    result = service.process(Path('test.xlsx'))

    assert len(result) == 2
    assert result['name'].tolist() == ['Alice', 'Bob']
    mock_parser.parse.assert_called_once()
    mock_validator.validate.assert_called_once()

def test_processing_service_validation_failure(mock_parser, mock_validator):
    """Test processing service with validation errors."""
    mock_validator.validate.return_value = ['Missing required column']

    service = ProcessingService(mock_parser, mock_validator)

    with pytest.raises(ValidationError, match='Missing required column'):
        service.process(Path('test.xlsx'))
```

### Test Quality Guidelines

- Test behavior, not implementation
- One assertion per test (generally)
- Use descriptive test names: `test_<what>_<when>_<expected>`
- Use fixtures for common setup
- Mock external dependencies (APIs, databases, file I/O)
- Aim for >80% code coverage

### Running Tests

```bash
# Run all tests
pytest tests/ -v

# Run specific test file
pytest tests/unit/test_parsers.py -v

# Run with coverage
pytest tests/ --cov=src --cov-report=term-missing

# Run only unit tests (skip slow e2e)
pytest tests/unit/ -v

# Run only marked tests
pytest -m "not e2e"  # Skip e2e tests
pytest -m e2e        # Run only e2e tests
```

---

## Development Workflow

### ⚠️ CRITICAL: Pull Request Requirement

**ALWAYS use pull requests. NEVER push directly to the default branch (main/master). No exceptions.**

This is a non-negotiable organizational standard that applies to:
- ✅ All code changes, no matter how small
- ✅ Documentation updates, even one-line fixes
- ✅ Configuration changes
- ✅ Everything

**Why this matters:**
- Enables code review and quality checks
- Prevents accidental breakage of main branch
- Creates audit trail of all changes
- Allows CI/CD to validate changes before merge
- Facilitates collaboration and knowledge sharing

**The only way to change the default branch:**
1. Create a feature branch
2. Make your changes on the branch
3. Push the feature branch to remote
4. Create a pull request
5. Wait for review and CI checks
6. Merge the PR (never force push or bypass)

**If you accidentally push to main:**
1. Immediately revert the commit
2. Create a feature branch from that commit
3. Create a PR with the changes
4. Merge through proper process

### Daily Development

```bash
# 1. Activate virtual environment
source .venv/bin/activate

# 2. Create feature branch
git checkout -b feature/my-feature

# 3. Make changes

# 4. Run tests
pytest tests/ -v

# 5. Check linting
ruff check --fix src/ tests/

# 6. Format code
ruff format src/ tests/

# 7. Type check
mypy src/

# 8. Commit changes
git add .
git commit -m "feat: add my feature"

# 9. Push and create PR
git push -u origin feature/my-feature
```

### Pre-Commit Hooks

Install pre-commit to run checks automatically:

```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install

# Now hooks run automatically on git commit!
```

**What runs on commit**:
- Ruff linting and formatting
- mypy type checking
- File size limit enforcement (500 lines)
- Trailing whitespace removal
- YAML validation
- Large file check

### Code Review Checklist

When reviewing code, check for:

- [ ] Type hints on all functions
- [ ] Tests for new functionality
- [ ] Structured logging (no print statements)
- [ ] File size under 500 lines
- [ ] Proper error handling (specific exceptions only)
- [ ] Consistent with existing code patterns
- [ ] Documentation updated if needed
- [ ] No hard-coded configuration
- [ ] Dependencies injected, not created
- [ ] Functions do one thing only

---

## Documentation Standards

### Documentation as Code

**Documentation lives with code, in code. Not in separate wikis.**

### Docstrings - Google Style

```python
def process_data(
    data: pd.DataFrame,
    threshold: float = 0.8,
    mode: ProcessingMode = ProcessingMode.NORMALIZE
) -> tuple[pd.DataFrame, list[str]]:
    """
    Process dataframe with specified threshold and mode.

    Applies normalization, validation, and transformation based on mode.
    Returns both processed data and any validation errors encountered.

    Args:
        data: Input dataframe with raw data
        threshold: Confidence threshold for filtering (0.0 to 1.0)
        mode: Processing mode - NORMALIZE, VALIDATE, or TRANSFORM

    Returns:
        Tuple of (processed_dataframe, error_messages)

    Raises:
        ValueError: If threshold not in range [0.0, 1.0]
        KeyError: If required columns missing from dataframe

    Example:
        >>> df = pd.DataFrame({'value': [1, 2, 3]})
        >>> result, errors = process_data(df, threshold=0.9)
        >>> print(f"Processed {len(result)} rows, {len(errors)} errors")
        Processed 3 rows, 0 errors
    """
    if not 0.0 <= threshold <= 1.0:
        raise ValueError(f"Threshold must be in [0.0, 1.0], got {threshold}")

    # Implementation...
```

### Type Hints as Documentation

```python
from typing import TypedDict, Literal

# Type aliases document domain concepts
UserID = str
ConfidenceLevel = Literal['HIGH', 'MEDIUM', 'LOW']

# TypedDict documents data structures
class ProcessingResult(TypedDict):
    """
    Result of data processing operation.

    Attributes:
        success: Whether processing completed successfully
        rows_processed: Number of rows processed
        errors: List of error messages encountered
        confidence: Overall confidence level of results
    """
    success: bool
    rows_processed: int
    errors: list[str]
    confidence: ConfidenceLevel
```

### README Structure

Every project should have a comprehensive README:

```markdown
# Project Name

Brief description (1-2 sentences)

## Quick Start

```bash
# Setup
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"

# Run tests
pytest tests/

# Run application
python -m myproject
```

## Development

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)

## Architecture

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)
```

### ADRs (Architecture Decision Records)

Document significant decisions in `adr/` directory:

```markdown
# ADR-001: Use Pydantic for Data Validation

**Status**: Accepted

**Context**:
We need robust data validation for user input and external APIs.

**Decision**:
Use Pydantic v2 for all data validation and settings management.

**Consequences**:
- Automatic validation on model instantiation
- Better error messages for users
- Type hints become runtime validation
- Integrates well with FastAPI if we build an API

**Alternatives Considered**:
- Marshmallow: More boilerplate, less Pythonic
- Cerberus: Less type-safe
- Manual validation: Error-prone, not DRY
```

---

## Code Quality Tools

### Ruff - All-in-One Linter + Formatter

**Why Ruff?**
- 10-100x faster than existing tools (written in Rust)
- Replaces Black, Flake8, isort, and more
- Used by Pandas, FastAPI, Pydantic

**Configuration** (`pyproject.toml`):
```toml
[tool.ruff]
line-length = 100
target-version = "py311"

select = [
    "E",   # pycodestyle errors
    "W",   # pycodestyle warnings
    "F",   # pyflakes
    "I",   # isort (import sorting)
    "N",   # pep8-naming
    "UP",  # pyupgrade (modernize syntax)
    "B",   # bugbear (common bugs)
    "C4",  # comprehensions
    "SIM", # simplify
]

ignore = [
    "E501",  # Line too long (formatter handles it)
]

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
```

**Usage**:
```bash
# Lint and auto-fix
ruff check --fix .

# Format code
ruff format .

# Both in one command
ruff check --fix . && ruff format .
```

### mypy - Type Checking

**Configuration** (`pyproject.toml`):
```toml
[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
```

**Usage**:
```bash
# Type check entire src
mypy src/

# Type check specific file
mypy src/myproject/parser.py
```

### pytest - Testing

**Configuration** (`pyproject.toml`):
```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
addopts = [
    "-v",
    "--strict-markers",
    "--tb=short",
]
markers = [
    "e2e: end-to-end tests (may be slow)",
    "unit: fast unit tests",
]
```

### Pre-commit Configuration

`.pre-commit-config.yaml`:
```yaml
repos:
  # Ruff - linting and formatting
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.1.9
    hooks:
      - id: ruff
        args: [--fix, --exit-non-zero-on-fix]
      - id: ruff-format

  # Type checking
  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.7.1
    hooks:
      - id: mypy
        additional_dependencies: [pydantic>=2.0]
        args: [--strict]

  # File size limit
  - repo: local
    hooks:
      - id: file-size-check
        name: Check file size < 500 lines
        entry: python scripts/check_file_size.py
        language: python
        types: [python]

  # Standard checks
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
        args: [--maxkb=1000]
```

---

## Summary

These standards ensure our code is:

- **Readable**: Clear intent, minimal cognitive load
- **Maintainable**: Easy to modify without breaking things
- **Testable**: Isolated components, dependency injection
- **Robust**: Fail fast, validate early, log everything
- **Scalable**: Separation of concerns, composition, focused interfaces

### Before Writing Code, Ask:

1. Is this the simplest solution that works?
2. Can this logic be reused elsewhere?
3. Will this be obvious to someone reading it in 6 months?
4. Can we test this easily?
5. Does this follow our conventions?

### Our Tech Stack (Python):

- **Python 3.11+** (latest stable)
- **Pydantic** (data validation)
- **Protocols** (structural typing)
- **Ruff** (linting + formatting)
- **mypy** (type checking)
- **pytest** (testing)
- **pre-commit** (automated quality checks)

---

**Status**: These standards apply to all organizational projects. They will be synced via the Claude Code automation sync tool to ensure consistency across the organization.
