# Contributing to CKAN Fork

This document will guide you through the process of making contributions. Please take a moment to read through this guide to make the contribution process easy and effective for everyone involved.

## Getting Started

1. **Clone the repository**: Clone the repository so you can start developing locally.
2. **Set up your development environment**: Follow the setup instructions in the README to set up your local environment.

## Contribution Workflow

### Find something to work on

Before starting work, check the issue tracker for existing issues or discussions. If you have a new idea or have found a bug, please open a new issue to discuss it before starting work.

### Determine if the issue is related to CKAN or a CKAN extension

There are many extensions that are a part of this project. See the "CKAN Extensions" section to understand the scope covered by extensions to determine where to contribute. If the changes should be made on an extension:

1. **Create or find a related issue in the extension repo**: If none exists within the extension repo and create a branch on it.
2. **Follow the "Making Changes" instructions to make changes in that repo**
3. **Continue within the cioos-siooc/ckan repo to update submodules**

#### CKAN Extensions

This repository specifically handles the easy installation of a CIOOS-SIOOC CKAN instance through docker with the requisite extensions being installed. Any contributions to that end can be done within this repository. Often, changes will need to be made to extensions, most of which we manage as forks of the original extension. To figure out what extension to contribute to, see the brief description here. If more information is needed, see the README.md at the given link, and the CIOOS-SIOOC Changes section if one exists.

|Submodule|cioos/siooc Repository?|Description|Repository|
|---------|-----------------|-----------|:--------:|
|ckanext-cioos_theme|✅|Themes CKAN for CIOOS-SIOOC to customize displayed metadata fields and support searching by EOV.|[link](https://github.com/cioos-siooc/ckanext-cioos_theme.git)|
|ckanext-harvest|✅|Enables harvesting from a variety of sources. Our fork enables deletion of remote datasets that no longer exist, and the ability to filter datasets to include or exclude.|[link](https://github.com/cioos-siooc/ckanext-harvest.git)|
|ckanext-spatial|✅|Allows the import of geospatial metadata into CKAN. Our fork handles the ability to parse of ISO 19115 xml metadata, and implements some CIOOS-SIOOC specific requirements, such as EOVs & ECVs, geospatial information.|[link](https://github.com/cioos-siooc/ckanext-spatial.git)|
|ckanext-scheming|✅|Defines the schema for the datasets. Much of this is handled through the `cioos-siooc-schema` repository, but this repository includes some customization of the original `ckanext-scheming` extension, such as placeholders and specific validation as determined by CIOOS-SIOOC|[link](https://github.com/cioos-siooc/ckanext-scheming.git)|
|cioos-siooc-schema|✅|A custom extension to contribute custom CIOOS-SIOOC metadata for the `ckanext-scheming` repository, such as EOVs and specific schemas for groups, organizations and licenses.|[link](https://github.com/cioos-siooc/cioos-siooc-schema.git)|
|ckanext-fluent|✅|Enables CKAN to be multilingual.|[link](https://github.com/cioos-siooc/ckanext-fluent.git)|
|ckanext-cioos_harvest|✅|A custom extension to translate ISO 19115-3 (xml implmentation) into the ISO 19115-1 format.|[link](https://github.com/cioos-siooc/ckanext-cioos_harvest.git)|
|ckanext-geoview|❌|An extension providing the Geospatial viewer for CKAN.|[link](https://github.com/ckan/ckanext-geoview.git)|
|ckanext-dcat|❌|Enables CKAN metadata to be translated to serialized RDF.|[link](https://github.com/ckan/ckanext-dcat.git)|

#### Update Submodules

### Making Changes

1. **Create a branch**: Always work on a new branch rather than the main branch. Create the branch through a Github issue and check it out locally.
2. **Make your changes**: Implement your feature or fix, adhering to the code style and practices used in the project.
3. **Test your changes**: Run the existing tests and add new ones if necessary to cover your changes. Make sure all tests pass.
4. **Document your changes**: Update the README, docstrings, or other documentation as needed to reflect your changes.

### Committing Your Changes

- **Write meaningful commit messages**: Include a brief description of changes made. Start with a short summary (50 characters or less), followed by a detailed description if needed.
- **Commit often**: Smaller, more frequent commits are preferred over one large commit when you finish.

### Pull Requests

1. **Push your changes to your fork**.
2. **Open a pull request**: Target the repository’s `cioos_dev` branch. Fill in the pull request template, including what your code does and any other relevant details.
3. **Review process**: Maintain an active dialogue if there are any comments or suggestions from the maintainers.

## Coding Standards

- **Code style**: Follow the coding style and conventions used in the project. If available, use linters and formatters to ensure your code conforms to these standards.
- **Documentation**: Ensure that every function is properly documented, following the documentation standards used in the project.
- **Testing**: Aim for thorough test coverage. Include unit tests for all new features and bug fixes.

## Need help?

If you need help with anything, feel free to ask questions on the community communication channels or directly in GitHub issues.

Thank you for contributing to our CKAN fork. We appreciate your efforts to improve this project!
