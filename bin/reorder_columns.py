import pandas as pd
import argparse

def reorder_columns(input_file, output_file, mark_order):
    with open(input_file, 'r') as file:
        first_line = file.readline().strip()
        print(first_line)
    df = pd.read_csv(input_file, skiprows=1, sep='\t')
    df_reorder = df[mark_order]

    with open(output_file, 'w') as file:
        file.write(first_line + '\n')
        df_reorder.to_csv(file, sep='\t', index=False)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Reorder columns in a CSV file.")
    parser.add_argument("input_file", help="Path to the input CSV file.")
    parser.add_argument("output_file", help="Path to the output CSV file.")
    parser.add_argument("mark_order", help="Comma-separated list of column names specifying the model order.")

    args = parser.parse_args()
    mark_order = args.mark_order.split(',')

    reorder_columns(args.input_file, args.output_file, mark_order)