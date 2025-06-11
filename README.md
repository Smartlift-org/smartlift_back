This is the backend component of the mobile application for sports clubs and gyms. Implemented with Ruby on Rails, this backend manages the core business logic, including user administration (members and trainers), training routine management (creation, storage, AI integration), user progress tracking, and the infrastructure for the social feed and other services.

It acts as the main API serving data to the mobile application (built with React Native) and orchestrates integration with external services such as the AI routine generation API and the exercise video storage system.

## Exercise IDs

The exercise IDs in this system range from 98 to 970. This range is maintained to ensure compatibility with the external exercise database we integrate with. When working with exercises in the API, make sure to use IDs within this range.

Ongoing...
