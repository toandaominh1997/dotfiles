use ratatui::{
    backend::CrosstermBackend,
    crossterm::{
        event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode},
        execute,
        terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
    },
    layout::{Alignment, Constraint, Direction, Layout},
    style::{Color, Modifier, Style},
    widgets::{Block, Borders, List, ListItem, ListState, Paragraph},
    Terminal,
};
use std::io;

#[derive(Clone, Copy)]
pub enum MenuAction {
    InstallEverything,
    InstallPackages,
    SetupZsh,
    SetupTmux,
    SetupVim,
    InstallFonts,
    SystemDashboard,
    UpgradeSetup,
    RunDoctor,
    SyncDotfiles,
    Quit,
}

struct App {
    state: ListState,
    items: Vec<(&'static str, MenuAction)>,
}

impl App {
    fn new() -> App {
        let mut state = ListState::default();
        state.select(Some(0));
        App {
            state,
            items: vec![
                (
                    "🚀 Install Everything (Default)",
                    MenuAction::InstallEverything,
                ),
                (
                    "📦 Install Homebrew & Packages",
                    MenuAction::InstallPackages,
                ),
                ("🐚 Setup Zsh & Themes", MenuAction::SetupZsh),
                ("💻 Setup Tmux", MenuAction::SetupTmux),
                ("📝 Setup Vim & Neovim", MenuAction::SetupVim),
                ("🔤 Install Fonts", MenuAction::InstallFonts),
                ("📈 System Dashboard", MenuAction::SystemDashboard),
                ("🔄 Upgrade Existing Setup", MenuAction::UpgradeSetup),
                ("🩺 Run Health Check", MenuAction::RunDoctor),
                ("🔄 Sync Dotfiles", MenuAction::SyncDotfiles),
                ("❌ Quit", MenuAction::Quit),
            ],
        }
    }

    pub fn next(&mut self) {
        let i = match self.state.selected() {
            Some(i) => {
                if i >= self.items.len() - 1 {
                    0
                } else {
                    i + 1
                }
            }
            None => 0,
        };
        self.state.select(Some(i));
    }

    pub fn previous(&mut self) {
        let i = match self.state.selected() {
            Some(i) => {
                if i == 0 {
                    self.items.len() - 1
                } else {
                    i - 1
                }
            }
            None => 0,
        };
        self.state.select(Some(i));
    }
}

pub fn show_menu() -> io::Result<Option<MenuAction>> {
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    let mut app = App::new();
    let res = run_app(&mut terminal, &mut app);

    disable_raw_mode()?;
    execute!(
        terminal.backend_mut(),
        LeaveAlternateScreen,
        DisableMouseCapture
    )?;
    terminal.show_cursor()?;

    Ok(res)
}

fn run_app(
    terminal: &mut Terminal<CrosstermBackend<io::Stdout>>,
    app: &mut App,
) -> Option<MenuAction> {
    loop {
        let _ = terminal.draw(|f| {
            let chunks = Layout::default()
                .direction(Direction::Vertical)
                .margin(2)
                .constraints([Constraint::Length(8), Constraint::Min(0)].as_ref())
                .split(f.area());

            let ascii_art = r#"
    ____        __               
   / __ \____  / /___  ______    
  / / / / __ \/ __/ / / / __ \   
 / /_/ / /_/ / /_/ /_/ / /_/ /   
/_____/\____/\__/\__,_/ .___/    
                     /_/         "#;

            let header = Paragraph::new(ascii_art)
                .style(
                    Style::default()
                        .fg(Color::Cyan)
                        .add_modifier(Modifier::BOLD),
                )
                .alignment(Alignment::Center)
                .block(
                    Block::default()
                        .borders(Borders::BOTTOM)
                        .title("Dotfiles Setup & Manager"),
                );

            f.render_widget(header, chunks[0]);

            let items: Vec<ListItem> = app.items.iter().map(|i| ListItem::new(i.0)).collect();

            let list = List::new(items)
                .block(Block::default().title(" Menu ").borders(Borders::ALL))
                .highlight_style(
                    Style::default()
                        .bg(Color::DarkGray)
                        .fg(Color::White)
                        .add_modifier(Modifier::BOLD),
                )
                .highlight_symbol(">> ");

            f.render_stateful_widget(list, chunks[1], &mut app.state);
        });

        if let Ok(Event::Key(key)) = event::read() {
            match key.code {
                KeyCode::Char('q') | KeyCode::Esc => return Some(MenuAction::Quit),
                KeyCode::Down | KeyCode::Char('j') => app.next(),
                KeyCode::Up | KeyCode::Char('k') => app.previous(),
                KeyCode::Enter => {
                    if let Some(i) = app.state.selected() {
                        return Some(app.items[i].1);
                    }
                }
                _ => {}
            }
        }
    }
}
