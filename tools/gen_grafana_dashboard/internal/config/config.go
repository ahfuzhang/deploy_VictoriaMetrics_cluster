package config

import (
	"os"

	"gopkg.in/yaml.v3"
)

type MetricConfig struct {
	Unit string `yaml:"unit"`
}

type Metrics struct {
	Counter        map[string]MetricConfig `yaml:"counter"`
	Guage          map[string]MetricConfig `yaml:"guage"`
	Heatmap        map[string]MetricConfig `yaml:"heatmap"`
	Value          map[string]MetricConfig `yaml:"value"`
	TimestampValue map[string]MetricConfig `yaml:"timestamp_value"`
	Text           map[string]MetricConfig `yaml:"text"`
}

type Dashboard struct {
	UID         string  `yaml:"uid"`
	Title       string  `yaml:"title"`
	Description string  `yaml:"description"`
	Labels      string  `yaml:"labels"`
	Metrics     Metrics `yaml:"metrics"`
}

type Configs struct {
	Dashboard Dashboard `yaml:"dashboard"`
}

var cfg Configs

func Load(f string) error {
	content, err := os.ReadFile(f)
	if err != nil {
		return err
	}
	err = yaml.Unmarshal(content, &cfg)
	if err != nil {
		return err
	}
	return nil
}

func Get() *Configs {
	return &cfg
}
