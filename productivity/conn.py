import curses
import pandas as pd
import subprocess

# Global variables
csv_file = '~/bin/conn3.dat'
data = pd.read_csv(csv_file)
filtered_data = data
filter_text = ""
selected_index = 0
username = "d496869a"

def filter_data():
    global filtered_data
    if filter_text:
        filtered_data = data[data.apply(lambda row: row.astype(str).str.contains(filter_text, case=False).any(), axis=1)]
    else:
        filtered_data = data.copy()  # Ensure a fresh copy to avoid side effects

def display(stdscr):
    global filter_text, selected_index
    curses.curs_set(0)
    stdscr.clear()

    # Display filter text
    try:
        stdscr.addstr(0, 0, "Filter: " + filter_text)
    except curses.error:
        pass  # Handle error if the string cannot be displayed

    # Display filtered data
    for idx, row in enumerate(filtered_data.iterrows()):
        # Pad each field to 30 spaces
        line = ' | '.join(f"{str(field):<30}" for field in row[1].values)
        try:
            if idx == selected_index:
                stdscr.addstr(idx + 1, 0, line, curses.A_REVERSE)
            else:
                stdscr.addstr(idx + 1, 0, line)
        except curses.error:
            pass  # Handle error if the string cannot be displayed

    stdscr.refresh()

def run(stdscr):
    global filter_text, selected_index
    try:
        while True:
            display(stdscr)
            key = stdscr.getch()

            if key == curses.KEY_BACKSPACE or key == 127:
                filter_text = filter_text[:-1]
            elif key == curses.KEY_ENTER or key in [10, 13]:
                if len(filtered_data) > 0:
                    selected_row = filtered_data.iloc[selected_index]
                    command_to_run = f"ssh {username}@{selected_row.iloc[0]}"  # SSH command using the first field
                    try:
                        stdscr.addstr(len(filtered_data) + 2, 0, f"Connecting to: {selected_row.iloc[0]}")
                    except curses.error:
                        pass  # Handle error if the string cannot be displayed
                    stdscr.refresh()

                    # Exit curses to run the SSH command
                    curses.endwin()  # Temporarily exit curses mode
                    subprocess.run(command_to_run, shell=True)  # Execute the SSH command

                    # Return to curses interface after the SSH session ends
                    curses.wrapper(run)
                    return
            elif key == curses.KEY_UP or key == ord('K'):  # Include Shift+K (uppercase K)
                selected_index = (selected_index - 1) % len(filtered_data) if len(filtered_data) > 0 else 0
            elif key == curses.KEY_DOWN or key == ord('J'):  # Include Shift+J (uppercase J)
                selected_index = (selected_index + 1) % len(filtered_data) if len(filtered_data) > 0 else 0
            elif key == 24:  # Ctrl+X
                filter_text = ""
                selected_index = 0
            else:
                filter_text += chr(key)

            filter_data()
    except KeyboardInterrupt:
        pass  # Gracefully exit on Ctrl-C
    finally:
        curses.endwin()  # Ensure the curses mode is exited properly

if __name__ == "__main__":
    curses.wrapper(run)



