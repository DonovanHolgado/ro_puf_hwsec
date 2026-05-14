import os
import csv
import numpy as np

# Data directories for each board
BOARDS = {
    "PYNQ-Z2": "/home/donovan/puf_data",
    "Zybo-1":  "/home/donovan/puf_data_zybo",
}

NUM_BITS = 128

def read_response(filepath):
    """Read response hex value from ILA CSV file"""
    try:
        with open(filepath, 'r') as f:
            lines = f.readlines()
            if len(lines) < 3:
                return None
            row = lines[2].strip().split(',')
            hex_val = row[3].strip()
            binary = bin(int(hex_val, 16))[2:].zfill(128)
            return binary
    except Exception as e:
        return None

def load_board_responses(data_dir):
    """Load all responses from a board's data directory"""
    responses = []
    if not os.path.exists(data_dir):
        print(f"Warning: Directory {data_dir} not found")
        return responses
    files = sorted([f for f in os.listdir(data_dir) if f.endswith('.csv')])
    for filename in files:
        filepath = os.path.join(data_dir, filename)
        response = read_response(filepath)
        if response and len(response) == NUM_BITS:
            responses.append(response)
    return responses

def calculate_uniformity(responses):
    """Calculate average percentage of 1s across all runs"""
    ones_counts = []
    for r in responses:
        ones = r.count('1')
        ones_counts.append(ones / NUM_BITS * 100)
    avg = np.mean(ones_counts)
    std = np.std(ones_counts)
    return avg, std

def calculate_reliability(responses):
    """Calculate bit error rate across all runs"""
    if len(responses) < 2:
        return 0, 0
    reference = responses[0]
    bit_errors = []
    for r in responses[1:]:
        errors = sum(a != b for a, b in zip(reference, r))
        bit_errors.append(errors / NUM_BITS * 100)
    avg_ber = np.mean(bit_errors)
    std_ber = np.std(bit_errors)
    return avg_ber, std_ber

def calculate_bit_stability(responses):
    """Find which bits are stable across all runs"""
    stable_bits = 0
    unstable_positions = []
    reference = responses[0]
    for pos in range(NUM_BITS):
        values = [r[pos] for r in responses]
        if len(set(values)) == 1:
            stable_bits += 1
        else:
            unstable_positions.append(pos)
    return stable_bits, unstable_positions

def hamming_distance(r1, r2):
    """Calculate Hamming distance between two responses as percentage"""
    diff = sum(a != b for a, b in zip(r1, r2))
    return diff / NUM_BITS * 100

def calculate_uniqueness(board_responses):
    """Calculate inter-device Hamming distances between all board pairs"""
    board_names = list(board_responses.keys())
    results = []

    for i in range(len(board_names)):
        for j in range(i+1, len(board_names)):
            board_a = board_names[i]
            board_b = board_names[j]
            responses_a = board_responses[board_a]
            responses_b = board_responses[board_b]

            if not responses_a or not responses_b:
                continue

            # Use median response from each board as representative
            # Compare all combinations between boards
            distances = []
            for ra in responses_a:
                for rb in responses_b:
                    distances.append(hamming_distance(ra, rb))

            avg_hd = np.mean(distances)
            std_hd = np.std(distances)
            results.append((board_a, board_b, avg_hd, std_hd))

    return results

def main():
    # Load responses for each board
    board_responses = {}
    for board_name, data_dir in BOARDS.items():
        responses = load_board_responses(data_dir)
        board_responses[board_name] = responses
        print(f"Loaded {len(responses)} responses from {board_name}")

    print("\n" + "="*50)
    print("PUF ANALYSIS RESULTS")
    print("="*50)

    # Per board analysis
    for board_name, responses in board_responses.items():
        if not responses:
            print(f"\n{board_name}: No valid responses found")
            continue

        print(f"\n{'='*50}")
        print(f"BOARD: {board_name} ({len(responses)} runs)")
        print(f"{'='*50}")

        # Uniformity
        avg_uni, std_uni = calculate_uniformity(responses)
        print(f"\nUNIFORMITY ANALYSIS")
        print(f"  Average: {avg_uni:.2f}%")
        print(f"  Std Dev: {std_uni:.2f}%")
        print(f"  Ideal:   50.00%")
        print(f"  Deviation from ideal: {abs(avg_uni - 50):.2f}%")

        # Reliability
        avg_ber, std_ber = calculate_reliability(responses)
        reliability = 100 - avg_ber
        print(f"\nRELIABILITY ANALYSIS")
        print(f"  Average Bit Error Rate: {avg_ber:.2f}%")
        print(f"  Std Dev BER: {std_ber:.2f}%")
        print(f"  Reliability: {reliability:.2f}%")
        print(f"  Ideal BER:   0.00%")

        # Bit stability
        stable, unstable = calculate_bit_stability(responses)
        print(f"\nBIT STABILITY ANALYSIS")
        print(f"  Stable bits:   {stable}/{NUM_BITS} ({stable/NUM_BITS*100:.2f}%)")
        print(f"  Unstable bits: {len(unstable)}/{NUM_BITS} ({len(unstable)/NUM_BITS*100:.2f}%)")

    # Uniqueness across boards
    print(f"\n{'='*50}")
    print("UNIQUENESS ANALYSIS (Inter-Device)")
    print(f"{'='*50}")

    uniqueness_results = calculate_uniqueness(board_responses)

    if not uniqueness_results:
        print("Not enough boards with data for uniqueness analysis")
    else:
        for board_a, board_b, avg_hd, std_hd in uniqueness_results:
            print(f"\n  {board_a} vs {board_b}:")
            print(f"    Average Hamming Distance: {avg_hd:.2f}%")
            print(f"    Std Dev: {std_hd:.2f}%")
            print(f"    Ideal: 50.00%")

        # Overall uniqueness
        all_hds = [r[2] for r in uniqueness_results]
        print(f"\n  Overall Average Uniqueness: {np.mean(all_hds):.2f}%")
        print(f"  Ideal: 50.00%")
        print(f"  Published benchmark (Suh & Devadas): 46.15%")

    # Save results
    output_path = "/home/donovan/puf_data/analysis_results_all_boards.txt"
    with open(output_path, 'w') as f:
        f.write("PUF ANALYSIS RESULTS - ALL BOARDS\n")
        f.write("="*50 + "\n\n")

        for board_name, responses in board_responses.items():
            if not responses:
                continue
            avg_uni, std_uni = calculate_uniformity(responses)
            avg_ber, std_ber = calculate_reliability(responses)
            reliability = 100 - avg_ber
            stable, unstable = calculate_bit_stability(responses)

            f.write(f"Board: {board_name}\n")
            f.write(f"  Runs: {len(responses)}\n")
            f.write(f"  Uniformity: {avg_uni:.2f}% (std: {std_uni:.2f}%)\n")
            f.write(f"  Reliability: {reliability:.2f}% (BER: {avg_ber:.2f}%)\n")
            f.write(f"  Stable bits: {stable}/{NUM_BITS}\n\n")

        f.write("UNIQUENESS (Inter-Device Hamming Distance)\n")
        for board_a, board_b, avg_hd, std_hd in uniqueness_results:
            f.write(f"  {board_a} vs {board_b}: {avg_hd:.2f}% (std: {std_hd:.2f}%)\n")

        if uniqueness_results:
            all_hds = [r[2] for r in uniqueness_results]
            f.write(f"\n  Overall Average: {np.mean(all_hds):.2f}%\n")

    print(f"\nResults saved to {output_path}")

if __name__ == "__main__":
    main()
