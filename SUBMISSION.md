# Lab 3 submission checklist

1. In an internet-connected Linux/devcontainer terminal, run `./scripts/api_lab.sh` from the repository root.
2. Confirm `logs/lab3.log` contains `LAB3_START`, `BASH_OK`, `CURL_JOKE_OK`, `JQ_JOKE_OK`, `DECK_CREATE_OK`, `DECK_DRAW_OK`, `JQ_DECK_OK`, and `LAB3_END`.
3. In Postman, send a GET request to `https://icanhazdadjoke.com/` with header `Accept: application/json`. Capture a screenshot showing request headers, HTTP status, and JSON body.
4. Use the Postman Code Generator to view cURL and Python exports. Replace the equivalent snippets in `data/` with those exports if necessary, and capture a screenshot of the generator.
5. In Postman, send `https://deckofcardsapi.com/api/deck/new/shuffle/?deck_count=1`, copy the returned `deck_id`, then send `https://deckofcardsapi.com/api/deck/DECK_ID/draw/?count=2`. Capture a screenshot showing the workflow and responses.
6. Submit those three screenshots and this reflection in Canvas:

   GET retrieves a resource without requesting a change to it, while POST submits data to a server and can create or modify resources. HTTP 200 means the request succeeded, whereas HTTP 404 means the requested resource could not be found.

7. Commit and push the repository to your GitHub Classroom repository, then open a pull request targeting `main`.

**Note:** Live API output, Postman screenshots, Canvas submission, and the GitHub pull request must be completed in your own connected environment.
