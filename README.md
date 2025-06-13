# 📽️ The Cinephile
An API-only **(Backend)** Rails application that allows users to create and manage their favorite movie lists, fetch trending movies & TV shows, review movies, and interact with other cinephiles. 

## 🛠️ Tech Stack
***The frontend part is available here: [The Cinephile Frontend](https://github.com/arunava-webdev4u/the-cinephile-frontend)***
- **🖥️ Backend:** Ruby on Rails (API-only)
    - **💎 Ruby Version:** `3.3.7 (2025-01-15 revision be31f993d7)`
    - **🛤️ Rails Version:** `8.0.1`
    - **🪨 Gem Version:** `3.5.22`
- **🗄️ Database:**
    - **🐘 PostgreSQL:** `17.2`
- **🔌 External APIs:**
    - [TMDB](https://www.themoviedb.org/) (Fetch info about movies/shows)
- **Authentication:** (Planned for future)

## 🚀 Getting Started
### 1️⃣ Clone the Repository
```sh
git clone https://github.com/yourusername/the-cinephile.git
cd the-cinephile
```
### 2️⃣ Install Dependencies
```sh
bundle install
```
### 3️⃣ Set Up Database
```sh
rails db:create db:migrate
```
### 4️⃣ Set Up Environment Variables
You'll need a TMDB API key. Create a .env file and add:
```ini
TMDB_API_KEY=your_api_key_here
```
### 5️⃣ Start the Server
```sh
rails server
```
### 6️⃣ Run Tests
```sh
rspec
```
### 7️⃣ Run Linter
```sh
rubocop
```

## 🗺️ Project Diagrams
This project uses **Draw.io** (diagrams.net) for architectural and flow diagrams. We maintain both source (.drawio) and generated (.png) files in version control for easy visualization on GitHub.
### Prerequisites
- Draw.io Desktop - Required for diagram conversion
- Ruby - For running the conversion script
### Managing Diagrams
- Create or edit diagrams using Draw.io Desktop
- Save your .drawio files in appropriate location (can be anywhere in the project)
- Generate PNG versions using the conversion script:
    - Convert only modified diagrams: `ruby bin/tools/convert_diagrams.rb`
    - Force convert all diagrams: `ruby bin/tools/convert_diagrams.rb --force`

## 📡 API Endpoints
### 🎬 Movies
...
### 📺 TV Shows
...
### 👤 Users
...

## How to run the test suite
...

## Deployment instructions
...

## System dependencies
...

## Configuration
...

## Database creation
...

## Database initialization
...

## Services (job queues, cache servers, search engines, etc.)
...
