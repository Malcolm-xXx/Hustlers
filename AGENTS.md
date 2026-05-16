When installing or uninstalling packages as well as running commands always use uv

e.g.
uv add <package-name>
uv add <package-name> --dev
uv run <command>

Check [pyproject.toml] for commands to run using taskipy
e.g. uv run task <task-name>

Always verify the output of your code changes; Lint, format, typecheck.

Never write logic code in **init**.py

Always follow fastapi best practices for structuring and writing your code. (Search the web for that)

When wanting to implement a feature especially one that uses an external api or service, ALWAYS do a research first on how to implement the feature, use tools or mcps available to you (e..g websearch, etc.) and make sure you gain enough context and search on how it'll affect the application.

When implementing ambiguous instructions always ask for clarifications and questions on how to go about it (Don't make the decisions on your own)

When writing code make sure to write it in a reusable manner, follow best practicies like DRY, etc. and make sure to write it in a way that can be easily read and maintained.

Name files in a way that reflects their content and purpose, use descriptive names for functions, variables, and classes to enhance readability and maintainability.

Group related code together and if a piece of code is used in multiple places create a shared file or folder.

Make sure the code is of production quality.

When changing the API contract of an endpoint (whether it's the URI, request body, response, etc.) make sure to update the postman documentation [postman](./postman/) to.

Always type your code and avoid the use of `Any` type as much as possible, use type annotations to enhance code readability and maintainability.

Add short descriptions to endpoints and functions to explain their purpose and usage, this will help other developers understand the code better and faster, can be the fastapi description or a docstring for functions.

Remove Dead code and codes that are not being used, unless it's marked as going to be used.

Keep performance in mind when writing code, avoid writing code that can cause performance issues or bottlenecks, and always look for ways to optimize the code if needed.

Anything that can be a database query make it a database query to avoid round trips and improve performance, avoid doing data processing in the application code that can be done in the database.

99% of the time each service should map to at most one database query

Beofre implementing or using a function (even if has been declared locally) check if there is a shared function that does the same thing or if there is a utility function that can be used to avoid code duplication and follow DRY principle.

And if it's a function that can be used in multiple places and is not specific to a certain feature or module, make sure to put it in a shared utilities file or folder so it can be easily reused across the codebase.

And if a calculation can be done in a db (e.g. sum, count, etc.) use the db

Avoid unnecessary and verbose code, stick to what's needed. Aggregations, Joins, use them where necessary.

don't edit the migrations directly if there's a problem with the code fix it from there
