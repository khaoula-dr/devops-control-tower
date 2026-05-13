# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS builder
WORKDIR /source
COPY . .
RUN dotnet publish -c Release -o /app --self-contained false 

# Stage 2: Final
FROM mcr.microsoft.com/dotnet/runtime:7.0 AS final
WORKDIR /app
COPY --from=builder /app .
ENTRYPOINT ["dotnet", "Worker.dll"]




