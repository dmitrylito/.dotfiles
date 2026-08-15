# Custom layout with Nvim (Top Left), Terminal (Bottom Left), and AI (Right)

window_root "$PWD"
new_window "Dev"

split_h 35

# split_v 20 means the bottom pane will be 20% height
select_pane 1
split_v 20

select_pane 1
run_cmd "nvim"

select_pane 3
run_cmd "gemini" # Replace with your AI command if needed

select_pane 1
