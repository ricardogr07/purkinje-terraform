import torch
import torch.nn as nn
import torch.optim as optim

# Check if GPU is available
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f"Using device: {device}")

# Generate synthetic data (y = 2x + 1 + noise)
torch.manual_seed(0)
x = torch.unsqueeze(torch.linspace(-1, 1, 100), dim=1)
y = 2 * x + 1 + 0.2 * torch.randn(x.size())

# Move data to device
x, y = x.to(device), y.to(device)

# Define a simple model
model = nn.Sequential(
    nn.Linear(1, 10),
    nn.ReLU(),
    nn.Linear(10, 1)
).to(device)

# Define loss and optimizer
criterion = nn.MSELoss()
optimizer = optim.Adam(model.parameters(), lr=0.01)

# Train the model
for epoch in range(200):
    model.train()
    outputs = model(x)
    loss = criterion(outputs, y)

    optimizer.zero_grad()
    loss.backward()
    optimizer.step()

    if (epoch + 1) % 50 == 0:
        print(f"Epoch [{epoch+1}/200], Loss: {loss.item():.4f}")

# Print final weights
print("\nFinal model parameters:")
for name, param in model.named_parameters():
    if param.requires_grad:
        print(name, param.data)
