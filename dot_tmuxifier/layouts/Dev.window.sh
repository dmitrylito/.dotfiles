# dev.window.sh
# Custom layout with Nvim (Top Left), Terminal (Bottom Left), and AI (Right)

window_root "$PWD"
new_window "Dev"

# 1. Create the Right pane (AI) - 30% width
split_h 35

# 2. Go back to Left pane and split it for Nvim (Top) and Terminal (Bottom)
# split_v 20 means the bottom pane will be 20% height
select_pane 1
split_v 20

# 3. Setup panes
# Pane 1: Top Left (Nvim)
select_pane 1
run_cmd "nvim"

# Pane 3: Right (AI)
select_pane 3
run_cmd "gemini" # Replace with your AI command if needed

# Focus on Nvim
select_pane 1
