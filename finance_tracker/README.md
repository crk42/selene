# Finance Tracker - Personal Finance Dashboard

A modern, lightweight personal finance tracking application built with Ruby/Sinatra. Features a premium dark-themed UI, real-time financial summaries, and interactive data visualization.

![Dashboard Preview](dashboard_preview.png)

## Features

- **📊 Interactive Dashboard**: Real-time overview of your financial health.
- **💰 Financial Summaries**: Instant calculation of total income, expenses, and current balance.
- **📈 Trend Analysis**: 6-month interactive chart visualizing income vs. expenses trends.
- **📝 Transaction Management**: 
  - View detailed list of recent transactions.
  - **Create**: Add new income or expense records.
  - **Edit**: Modify existing transaction details via a modal interface.
  - **Delete**: Remove single transactions or use **bulk delete** for multiple items.
- **📂 Category Management**: Create and manage custom transaction categories.
- **📥 Data Import**: Import transactions from CSV files.
- **📱 Responsive Design**: fully optimized for desktop and mobile devices.
- **🌙 Dark Mode**: sleek, eye-strain-reducing dark interface with glassmorphism effects.

## Tech Stack

- **Backend**: Ruby 3.1+, Sinatra, ActiveRecord
- **Database**: SQLite3
- **Frontend**: HTML5, CSS3 (Custom Premium Design), Chart.js
- **Server**: Puma (via Rackup/WEBrick backup)

## Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/finance-tracker.git
   cd finance-tracker
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Set up the database**
   Run the setup script to create the database and seed it with sample data:
   ```bash
   bundle exec ruby setup_db.rb
   ```

4. **Start the server**
   You can start the server using the provided batch script (Windows):
   ```bash
   .\start_server.bat
   ```
   
   Or manually via rackup:
   ```bash
   bundle exec rackup -p 4567
   ```

5. **Access the application**
   Open your browser and navigate to: [http://localhost:4567](http://localhost:4567)

## Project Structure

- `app.rb`: Main application logic and routes.
- `views/`: ERB templates for the frontend.
- `public/`: Static assets (CSS, images).
- `setup_db.rb`: Database initialization and seeding script.
- `Gemfile`: Ruby dependency definitions.

## Future Roadmap

- [ ] Monthly reports and export functionality.
- [ ] User authentication.

## License

This project is open-source and available under the MIT License.
