library(tidyverse)
library(scales)
library(showtext)


font_add("chinese", "C:/Windows/Fonts/simsun.ttc")
font_add("english", "C:/Windows/Fonts/times.ttf")
showtext_auto()
# Output directory (same folder as this script)
out_dir <- "C:/Users/cai/OneDrive/Desktop"

# ── Data ──────────────────────────────────────────────────────────────────────
df <- tribble(
  ~edu, ~region,  ~pred,     ~lb,        ~ub,
  1,    "South",  0.1146944, 0.1007606,  0.1286282,
  1,    "North",  0.19292,   0.1757299,  0.2101101,
  2,    "South",  0.1511464, 0.1367757,  0.1655171,
  2,    "North",  0.2282747, 0.2117195,  0.2448298,
  3,    "South",  0.1956208, 0.1775373,  0.2137043,
  3,    "North",  0.2674562, 0.2492246,  0.2856877,
  4,    "South",  0.2482558, 0.2217876,  0.2747239,
  4,    "North",  0.3101786, 0.2872544,  0.3331028,
  5,    "South",  0.3085427, 0.2699152,  0.3471703,
  5,    "North",  0.3559844, 0.3259504,  0.3860184,
  6,    "South",  0.3752453, 0.3222821,  0.4282086,
  6,    "North",  0.4042531, 0.365674,   0.4428321,
  7,    "South",  0.4464338, 0.3787138,  0.5141539,
  7,    "North",  0.4542255, 0.4065317,  0.5019192
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
    region = factor(region, levels = c("South", "North"))
  )

# ── Plot ──────────────────────────────────────────────────────────────────────
p <- ggplot(df, aes(x = edu_label, y = pred,
                    color = region, fill = region,
                    group = region, shape = region)) +

  geom_ribbon(aes(ymin = lb, ymax = ub), alpha = 0.15, color = NA) +

  geom_line(linewidth = 0.9) +

  geom_point(size = 2.5, stroke = 0.8) +

  scale_shape_manual(values = c("South" = 21, "North" = 25)) +
  scale_color_manual(values = c("South" = "#4A8850", "North" = "#EE7D3A")) +
  scale_fill_manual(values  = c("South" = "#4A8850", "North" = "#EE7D3A")) +

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


showtext_opts(dpi = 300) 
ggsave(file.path(out_dir, "Regional_Heterogeneity.pdf"),
       plot = p, width = 8, height = 5, dpi = 300, device = cairo_pdf)

# TIFF (600 dpi, LZW compression, for journal production)

showtext_opts(dpi = 600) 
ggsave(file.path(out_dir, "Regional_Heterogeneity.tiff"),
       plot = p, width = 8, height = 5, dpi = 600,
       device = "tiff", compression = "lzw")

showtext_opts(dpi = 96) 

p


