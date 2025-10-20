# Privacy Report Kit

The Privacy Report Kit is a command for the Gemini CLI that generates a ROPA-ready (Record of Processing Activities) privacy report in JSON format by scanning a software repository.

## What it is

This tool helps developers and privacy teams understand how personal and sensitive data is handled within a codebase. It scans for potential Personally Identifiable Information (PII), authentication tokens, financial data, and other sensitive information, and then generates a structured JSON report based on its findings. This report can be used as a starting point for creating a formal Record of Processing Activities (ROPA) as required by privacy regulations like GDPR.

## Installation

To install the Privacy Report Kit, run the following command in your terminal:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/kandito/privacy-report-kit/main/install.sh)"
```

The `collect-privacy-context.sh` script is a powerful tool for identifying
potential PII and data stores.

### ORM Correlation

The script can automatically correlate PII with storage locations for the following ORMs:

*   **Spring JPA:** Extracts table and column names from `@Entity` annotated Java files.
*   **Mongoose:** Extracts collection and field names from Mongoose schema files.
*   **Prisma:** Extracts model and field names from Prisma schema files.

### Current Limitations

*   **Limited Automatic Correlation:** The script only automatically correlates
    PII with storage locations for Spring JPA, Mongoose, and Prisma projects.
    For other frameworks, manual analysis of the script's output is still
    required.

### Usage

1.  Navigate to the root directory of a git repository.
2.  Run the `privacy-report` command in your Gemini CLI:

    ```
    /privacy-report [path1] [path2] ...
    ```

    *   If no paths are provided, the entire repository will be scanned.
    *   You can specify one or more directories or files to limit the scope of the scan.

## Dependencies

*   **Gemini CLI:** This tool is a command for the Gemini CLI.
*   **ripgrep (`rg`):** The `collect-privacy-context.sh` script uses `ripgrep` to search for text in files. You can install it with `brew install ripgrep` or `apt-get install ripgrep`.
*   **jq (optional):** `jq` is a command-line JSON processor that can be useful for viewing and manipulating the output of the privacy report.

## Uninstall

To uninstall the Privacy Report Kit, you can run the `uninstall.sh` script:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/kandito/privacy-report-kit/main/uninstall.sh)"
```

## How it works

The Privacy Report Kit works in the following steps:

1.  **Installation:** The `install.sh` script sets up the `privacy-report` command in your Gemini CLI by cloning this repository and creating a symlink to the command configuration.
2.  **Execution:** When you run the `/privacy-report` command in a repository, it triggers the `privacy-report.toml` command definition.
3.  **Context Collection:** The command executes the `tools/collect-privacy-context.sh` script. This script uses `ripgrep` (`rg`) to scan the specified paths (or the entire repository by default) for keywords and patterns that suggest the presence of sensitive data. It looks for:
    *   PII and sensitive data fields (e.g., `email`, `phone`, `name`, `address`).
    *   Authentication and session management tokens (e.g., `jwt`, `session`, `oauth`).
    *   Database and ORM-related code (e.g., `CREATE TABLE`, `Sequelize.define`, `@Entity`).
    *   Third-party integrations and SDKs (e.g., `aws`, `firebase`, `stripe`).
    *   API endpoints and routes.
4.  **Report Generation:** The output of the context collection script, along with the `schemas/privacy_report.schema.json`, is passed to a large language model. The model then generates a single JSON object that conforms to the schema, filling in the details of the privacy report based on the evidence found in the code.
5.  **Output:** The final JSON report is outputted, providing a summary of the data processing activities, data transfers, integrations, and recommendations for improving data privacy.
