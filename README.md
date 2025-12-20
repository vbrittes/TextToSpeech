# CSTV
This is a Challenge Project to assess the developer technical skills. 
It uses Panda Score API to display current and upcoming Counter Strike matches on a list and also navigates to display further details.

## Libraries used
### Alamofire
Used to perform HTTP requests.
### Kingfisher
Used to perform image lazy loading and caching.

## Design pattern
### Architecture
The project was built over MVVM-Coordinator architecture, using Combine to assure UI and Business layers consistency.
### UI Framework
The UI was built using Storyboard for interface wireframing, and view-code for behaviour and formatting.
### Dependency management
All of the dependencies are managed by SPM, compatible to the latest versions respectively.
### Unit tests
Unit tests are focused mostly on View models, in order to detect formatting issues, loading misbehavior and API contract inconsistencies.

Mock services are provided based in json files for better consistency checking and easily test scenario update, either manually or via pipeline scripts.

## Running
To run the project, make sure the local main branch is updated with the remote and if possible use Xcode's latest version.

Before compiling, update SPM's dependencies; If any dependency error occurs, cleaning the cache is recommended.

## Optionals covered
- Unit tests ✅
- MVVM architecture (MVVM-C) ✅
- Pagination support ✅
- Reactive programming (Combine) ✅
- Responsiveness ⚠️
	- The content is displayed with no distortions, but no optimization was made
