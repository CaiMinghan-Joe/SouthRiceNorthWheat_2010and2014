library(tidyverse)
library(scales)

# Output directory (same folder as this script)
out_dir <- "C:/Users/cai/OneDrive/Desktop"

# ── Data ──────────────────────────────────────────────────────────────────────
df <- tribble(
  ~edu, ~income_group, ~pred,     ~lb,        ~ub,
  1,    "Low-income",  0.1844906, 0.1653578,  0.2036234,
  1,    "High-income", 0.1287646, 0.1130309,  0.1444983,
  2,    "Low-income",  0.2188766, 0.1990718,  0.2386813,
  2,    "High-income", 0.1651994, 0.1482217,  0.1821771,
  3,    "Low-income",  0.2571541, 0.2337140,  0.2805943,
  3,    "High-income", 0.2086116, 0.1882488,  0.2289744,
  4,    "Low-income",  0.2990822, 0.2688288,  0.3293356,
  4,    "High-income", 0.2589784, 0.2322160,  0.2857407,
  5,    "Low-income",  0.3442455, 0.3047813,  0.3837098,
  5,    "High-income", 0.3157762, 0.2798892,  0.3516632,
  6,    "Low-income",  0.3920595, 0.3419470,  0.4421720,
  6,    "High-income", 0.3779384, 0.3311900,  0.4246868,
  7,    "Low-income",  0.4417906, 0.3804765,  0.5031047,
  7,    "High-income", 0.4438902, 0.3857843,  0.5019962
) %>%
  mutate(
    edu_label = factor(edu, levels = 1:7,
                       labels = c("Illiterate",
                                  "Primary",
                                  "Junior high",
                                  "Senior high/\nVocational",
                                  "Junior college",
                                  "Bachelor's",
                                  "Master's+")),
    income_group = factor(income_group, levels = c("Low-income", "High-income"))
  )

# ── Plot ──────────────────────────────────────────────────────────────────────
p <- ggplot(df, aes(x = edu_label, y = pred,
                    color = income_group, fill = income_group,
                    group = income_group, shape = income_group)) +

  geom_ribbon(aes(ymin = lb, ymax = ub), alpha = 0.15, color = NA) +

  geom_line(linewidth = 0.9) +

  geom_point(size = 2.5, stroke = 0.8) +

  scale_shape_manual(values = c("Low-income" = 21, "High-income" = 25)) +
  scale_color_manual(values = c("Low-income" = "#4A8850", "High-income" = "#EE7D3A")) +
  scale_fill_manual(values  = c("Low-income" = "#4A8850", "High-income" = "#EE7D3A")) +

  scale_y_continuous(limits = c(0, 0.6),
                     breaks = seq(0, 0.6, 0.1),
                     labels = number_format(accuracy = 0.1),
                     expand = expansion(mult = c(0, 0.05))) +

  labs(
    # Title omitted per HSSC style (caption placed below figure in manuscript)
    x     = "Education Attainment",
    y     = "Predicted Probability of Exercise Participation",
    color = NULL, fill = NULL, shape = NULL
  ) +

  theme_classic(base_family = "serif", base_size = 14) +
  theme(
    plot.title         = element_blank(),
    axis.text.x        = element_text(angle = 0, hjust = 0.5, size = 16,
                                      family = "serif"),
    axis.text.y        = element_text(size = 16, family = "serif"),
    axis.title.x       = element_text(size = 18, family = "serif",
                                      margin = margin(t = 10)),
    axis.title.y       = element_text(size = 18, family = "serif",
                                      margin = margin(r = 10)),
    axis.ticks.length  = unit(-0.15, "cm"),
    axis.text.x.bottom = element_text(margin = margin(t = 0.3, unit = "cm")),
    axis.text.y.left   = element_text(margin = margin(r = 0.3, unit = "cm")),
    legend.position    = "bottom",
    legend.text        = element_text(size = 16, family = "serif"),
    legend.key.width   = unit(1.5, "cm"),
    panel.grid.major.y = element_line(color = "grey90", linewidth = 0.3)
  )

# ── Export ────────────────────────────────────────────────────────────────────
# PDF (vector, for manuscript submission)
ggsave(file.path(out_dir, "Income_Heterogeneity.pdf"),
       plot = p, width = 8, height = 5, dpi = 300, device = cairo_pdf)

# TIFF (600 dpi, LZW compression, for journal production)
ggsave(file.path(out_dir, "Income_Heterogeneity.tiff"),
       plot = p, width = 8, height = 5, dpi = 600,
       device = "tiff", compression = "lzw")
p


