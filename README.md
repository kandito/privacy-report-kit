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

## Configuration

The Privacy Report Kit can be configured using a `privacy-report.config.json` file in the root of your repository. This file allows you to specify the directories where your data models are defined and the directories that should be scanned for PII usage.

To generate a default configuration file, run the following command:

```
/privacy-report-config
```

This will create a `privacy-report.config.json` file with the following content:

```json
{
  "model_definition_paths": ["models/", "schemas/"],
  "code_coverage_paths": ["controllers/", "routes/", "services/"]
}
```

You can then customize these paths to match your project's structure.

## Usage

1.  Navigate to the root directory of a git repository.
2.  (Optional) Generate a configuration file using `/privacy-report-config` and customize it.
3.  Run the `privacy-report` or `privacy-report-json` command in your Gemini CLI:

    ```
    /privacy-report
    ```
    or
    ```
    /privacy-report-json
    ```

    *   If a `privacy-report.config.json` file is present, the tool will scan the specified `model_definition_paths` for PII and then search for usage of that PII in the `code_coverage_paths`.
    *   If no configuration file is found, the entire repository will be scanned.

## Dependencies

*   **Gemini CLI:** This tool is a command for the Gemini CLI.
*   **ripgrep (`rg`):** The `collect-privacy-context.sh` script uses `ripgrep` to search for text in files. You can install it with `brew install ripgrep` or `apt-get install ripgrep`.
*   **jq:** `jq` is a command-line JSON processor that is required for the new configuration file feature. You can install it with `brew install jq` or `apt-get install jq`.

## Uninstall

To uninstall the Privacy Report Kit, you can run the `uninstall.sh` script:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/kandito/privacy-report-kit/main/uninstall.sh)"
```

## How it works

The Privacy Report Kit works in the following steps:

1.  **Installation:** The `install.sh` script sets up the `privacy-report` command in your Gemini CLI by cloning this repository and creating a symlink to the command configuration.
2.  **Configuration (Optional):** You can generate a `privacy-report.config.json` file to specify the scope of the scan.
3.  **Execution:** When you run the `/privacy-report` or `/privacy-report-json` command in a repository, it triggers the corresponding `.toml` command definition.
4.  **Context Collection:** The command executes the `tools/collect-privacy-context.sh` script.
    *   If a configuration file is present, the script will first identify PII in the `model_definition_paths` and then search for their usage in the `code_coverage_paths`.
    *   Otherwise, it scans the entire repository for keywords and patterns that suggest the presence of sensitive data.
    It looks for:
    *   PII and sensitive data fields (e.g., `email`, `phone`, `name`, `address`).
    *   Authentication and session management tokens (e.g., `jwt`, `session`, `oauth`).
    *   Database and ORM-related code (e.g., `CREATE TABLE`, `Sequelize.define`, `@Entity`).
    *   Third-party integrations and SDKs (e.g., `aws`, `firebase`, `stripe`).
    *   API endpoints and routes.
5.  **Report Generation:** The output of the context collection script, along with the `schemas/privacy_report.schema.json`, is passed to a large language model. The model then generates a single JSON object that conforms to the schema, filling in the details of the privacy report based on the evidence found in the code.
6.  **Output:** The final JSON or Markdown report is outputted, providing a summary of the data processing activities, data transfers, integrations, and recommendations for improving data privacy.
