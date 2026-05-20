##### Time Series Analysis Project #####
### SARIMA Forecasting of California ILI Activity
### MATH 5140 — Time Series Analysis
### Joseph Bray Demonbreun

# ============================================================
# Step 1: Dataset Import (ILI National Data)
# Download dataset from CDC FluView:
# https://gis.cdc.gov/grasp/fluview/fluportaldashboard.html
# Save the CSV locally and update the path below.
# ============================================================

install.packages("readr")
library(readr)

ili_wkly_national_2014_to_2025 <- read_csv("ili_net.csv")
str(ili_wkly_national_2014_to_2025)

# ============================================================
# Step 2: Preprocess the Data
# - Filter to California only
# - Convert WEEKEND from string to Date
# - Convert ACTIVITY LEVEL text to numeric
# ============================================================

install.packages("dplyr")
library(dplyr)

ca_ili <- ili_wkly_national_2014_to_2025 %>%
  filter(STATENAME == "California") %>%
  mutate(WEEKEND = as.Date(WEEKEND, format = "%b-%d-%Y")) %>%
  mutate(`ACTIVITY NUM` = as.numeric(gsub("Level ", "", `ACTIVITY LEVEL`)))

str(ca_ili)

ca_ili %>%
  arrange(WEEKEND) %>%
  head(20)

# Check for gaps in weekly data
ca_ili %>%
  arrange(WEEKEND) %>%
  mutate(diff_days = c(NA, diff(WEEKEND))) %>%
  filter(diff_days > 7)

# ============================================================
# Step 3: Create Time Series Object
# Start: Week 40 of 2014 (start of flu season)
# Frequency: 52 (weekly, annual cycle)
# ============================================================

ca_ts <- ts(ca_ili$`ACTIVITY NUM`, start = c(2014, 40), frequency = 52)

# ============================================================
# Step 4: Plot Time Series
# ============================================================

plot(ca_ts,
     main = "ILI Activity Levels in California (Weekly, 2014-2025)",
     ylab = "ILI Level",
     xlab = "Year")

# ============================================================
# Step 5: Seasonal Decomposition (Additive)
# ============================================================

plot(decompose(ca_ts, type = "additive"))

# ============================================================
# Step 6: Stationarity Testing — ACF, PACF, ADF, KPSS
# ============================================================

par(mfrow = c(1, 2))
acf(ca_ts, main = "ACF")
pacf(ca_ts, main = "PACF")
par(mfrow = c(1, 1))

install.packages("tseries")
library(tseries)

adf.test(ca_ts)   # H0: Non-stationary
kpss.test(ca_ts)  # H0: Stationary

# Extended lag ACF/PACF to inspect seasonal component
acf(ca_ts, lag.max = 104, main = "Seasonal ACF")
pacf(ca_ts, lag.max = 104, main = "Seasonal PACF")

# ============================================================
# Step 7: Fit SARIMA Models
# Three candidates compared by AIC
# ============================================================

# Model A: SARIMA(0,0,0) x (1,1,1)[52]
modelA <- arima(ca_ts,
                order = c(0, 0, 0),
                seasonal = list(order = c(1, 1, 1), period = 52))
modelA

# Model B: SARIMA(1,0,0) x (1,1,1)[52] — Best AIC
modelB <- arima(ca_ts,
                order = c(1, 0, 0),
                seasonal = list(order = c(1, 1, 1), period = 52))
modelB

# Model C: SARIMA(0,0,1) x (1,1,1)[52]
modelC <- arima(ca_ts,
                order = c(0, 0, 1),
                seasonal = list(order = c(1, 1, 1), period = 52))
modelC

# ============================================================
# Step 8: Residual Diagnostics for Model B
# ============================================================

par(mfrow = c(3, 1))
ts.plot(residuals(modelB), main = "Residuals (Model B)")
acf(residuals(modelB), lag.max = 104, main = "ACF of Residuals (Model B)")
pacf(residuals(modelB), lag.max = 104, main = "PACF of Residuals (Model B)")
par(mfrow = c(1, 1))

# Ljung-Box Test for remaining autocorrelation
Box.test(residuals(modelB), lag = 24, type = "Ljung")
Box.test(residuals(modelB), lag = 52, type = "Ljung")

# ============================================================
# Step 9: Generate and Plot 52-Week Forecast
# ============================================================

library(forecast)

forecast_B <- forecast(modelB, h = 52)
forecast_B

plot(forecast_B,
     main = "California ILI Activity Level Forecast (52 weeks)",
     ylab = "ILI Level",
     xlab = "Year")
