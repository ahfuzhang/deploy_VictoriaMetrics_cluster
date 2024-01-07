package main

import (
	"bufio"
	_ "embed"
	"encoding/json"
	"flag"
	"fmt"
	"gen_grafana_dashboard/internal/config"
	. "gen_grafana_dashboard/internal/stringsutil"
	"log"
	"os"
	"sort"
	"strings"
	"text/template"

	"github.com/google/uuid"
)

//go:embed templates/grafana.json.tpl
var defaultTemplate string

type GridPos struct {
	X, Y, W, H int16
}

const (
	UnitOfShort   = "short"
	UnitOfBytes   = "decbytes"
	UnitOfSeconds = "s"
)

type Grid struct {
	MetricName  string
	Title       string
	Description string
	Pos         GridPos
	Unit        string
}

type TemplateParam struct {
	UID            string
	Title          string
	Description    string
	Labels         string // json format
	Guage          []Grid
	Counter        []Grid
	Heatmap        []Grid
	TimestampValue []Grid // 时间戳表示的值
	Value          []Grid
	Text           []Grid
}

var startY int16 = 1
var count = 1

func getPos() GridPos {
	count++
	return GridPos{
		W: 6,
		H: 8,
		X: int16((count - 1) % 4 * 6),
		Y: int16((count/4)*8 + int(startY)),
	}
}

func toJSONString(s string) string {
	str, _ := json.Marshal(s)
	//str, _ = json.Marshal(B2s(str))
	return B2s(str[1 : len(str)-1])
}

func getParam() *TemplateParam {
	cfg := config.Get()
	p := &TemplateParam{
		UID: func() string {
			if len(cfg.Dashboard.UID) > 0 {
				return cfg.Dashboard.UID
			} else {
				return uuid.New().String()
			}
		}(),
		Title:       cfg.Dashboard.Title,
		Description: cfg.Dashboard.Description,
		Labels:      toJSONString(cfg.Dashboard.Labels),
	}
	//从 yaml 插入
	addFromYaml(p)
	fromMetricFile(p)
	setPosOfGrid(p)
	return p
}

func addFromYaml(p *TemplateParam) {
	metrics := config.Get().Dashboard.Metrics
	for metricName, cfg := range metrics.Counter {
		p.Counter = append(p.Counter, Grid{
			MetricName: metricName,
			Unit:       cfg.Unit,
		})
	}
	for metricName, cfg := range metrics.Guage {
		p.Guage = append(p.Guage, Grid{
			MetricName: metricName,
			Unit:       cfg.Unit,
		})
	}
	for metricName, cfg := range metrics.Heatmap {
		p.Heatmap = append(p.Heatmap, Grid{
			MetricName: metricName,
			Unit:       cfg.Unit,
		})
	}
	for metricName, cfg := range metrics.Value {
		p.Value = append(p.Value, Grid{
			MetricName: metricName,
			Unit:       cfg.Unit,
		})
	}
	for metricName, cfg := range metrics.TimestampValue {
		p.TimestampValue = append(p.TimestampValue, Grid{
			MetricName: metricName,
			Unit:       cfg.Unit,
		})
	}
	for metricName, cfg := range metrics.Text {
		p.Text = append(p.Text, Grid{
			MetricName: metricName,
			Unit:       cfg.Unit,
		})
	}
}

var (
	metricFile   = flag.String("metric", "", "text file of metrics")
	templateFile = flag.String("template", "", "golang template file for grafana json")
	targetFile   = flag.String("target", "", "target file of grafana json")
	configFile   = flag.String("config", "./config.yaml", "config file to gen dashboard")
)

var (
	needSkipPrefix = []string{"go_", "process_", "flag"}
)

func setPosOfGrid(p *TemplateParam) {
	for i := range p.Counter {
		item := &p.Counter[i]
		item.Pos = getPos()
	}
	for i := range p.Guage {
		item := &p.Guage[i]
		item.Pos = getPos()
	}
	for i := range p.Heatmap {
		item := &p.Heatmap[i]
		item.Pos = getPos()
	}
	for i := range p.TimestampValue {
		item := &p.TimestampValue[i]
		item.Pos = getPos()
	}
	for i := range p.Value {
		item := &p.Value[i]
		item.Pos = getPos()
	}
	for i := range p.Text {
		item := &p.Text[i]
		item.Pos = getPos()
	}
}

func fromMetricFile(p *TemplateParam) {
	if len(*metricFile) == 0 {
		return
	}
	alreadyHaveNames := getMetricNames(p)
	metricFileNames, err := getMetricNamesOfMetricFile(*metricFile)
	if err != nil {
		log.Fatalln(err)
	}
	notAdded := make(map[string]struct{})
	for _, name := range sortKeys(metricFileNames) {
		if _, has := alreadyHaveNames[name]; has {
			continue
		}
		for _, prefix := range needSkipPrefix {
			if strings.HasPrefix(name, prefix) {
				goto Next
			}
		}
		if strings.HasSuffix(name, "_total") {
			if strings.HasSuffix(name, "_bytes_total") {
				p.Counter = append(p.Counter, Grid{
					MetricName: name,
					Unit:       UnitOfBytes,
					//Pos:        getPos(),
				})
			} else if strings.HasSuffix(name, "_seconds_total") {
				p.Counter = append(p.Counter, Grid{
					MetricName: name,
					Unit:       UnitOfSeconds,
					//Pos:        getPos(),
				})
			} else {
				p.Counter = append(p.Counter, Grid{
					MetricName: name,
					Unit:       UnitOfShort,
					//Pos:        getPos(),
				})
			}
			alreadyHaveNames[name] = struct{}{}
			continue
		}
		if strings.HasSuffix(name, "_bucket") {
			if strings.HasSuffix(name, "_seconds_bucket") {
				p.Heatmap = append(p.Heatmap, Grid{
					MetricName: name,
					Unit:       UnitOfSeconds,
					//Pos:        getPos(),
				})
			} else if strings.HasSuffix(name, "_bytes_bucket") {
				p.Heatmap = append(p.Heatmap, Grid{
					MetricName: name,
					Unit:       UnitOfBytes,
					//Pos:        getPos(),
				})
			} else {
				p.Heatmap = append(p.Heatmap, Grid{
					MetricName: name,
					Unit:       UnitOfShort,
					//Pos:        getPos(),
				})
			}
			prefix := name[:len(name)-len("bucket")]
			alreadyHaveNames[prefix+"sum"] = struct{}{}
			alreadyHaveNames[prefix+"count"] = struct{}{}
			continue
		}
		if strings.HasSuffix(name, "_bytes") {
			p.Guage = append(p.Guage, Grid{
				MetricName: name,
				Unit:       UnitOfBytes,
				//Pos:        getPos(),
			})
			alreadyHaveNames[name] = struct{}{}
			continue
		}
		notAdded[name] = struct{}{}
	Next:
	}
	formatNotAdded(p, notAdded)
}

func formatNotAdded(p *TemplateParam, notAdded map[string]struct{}) {
	s := strings.Builder{}
	for _, name := range sortKeys(notAdded) {
		s.WriteString("* ")
		s.WriteString(name)
		s.WriteByte('\n')
	}
	str, _ := json.Marshal(s.String())
	p.Text = append(p.Text, Grid{
		Title:       "not added metrics",
		Description: B2s(str),
		Pos:         getPos(),
	})
}

func sortKeys(m map[string]struct{}) []string {
	out := make([]string, 0, len(m))
	for k := range m {
		out = append(out, k)
	}
	sort.Strings(out)
	return out
}

func getMetricNames(p *TemplateParam) map[string]struct{} {
	names := make(map[string]struct{})
	for _, item := range p.Counter {
		names[item.MetricName] = struct{}{}
	}
	for _, item := range p.Guage {
		names[item.MetricName] = struct{}{}
	}
	for _, item := range p.TimestampValue {
		names[item.MetricName] = struct{}{}
	}
	for _, item := range p.Value {
		names[item.MetricName] = struct{}{}
	}
	return names
}

func getMetricNamesOfMetricFile(f string) (map[string]struct{}, error) {
	content, err := os.ReadFile(f)
	if err != nil {
		return nil, err
	}
	scanner := bufio.NewScanner(strings.NewReader(B2s(content)))
	names := make(map[string]struct{})
	for scanner.Scan() {
		line := scanner.Text() // 获取当前行的内容
		idx := strings.IndexByte(line, '{')
		if idx == -1 {
			continue
		}
		names[line[:idx]] = struct{}{}
	}
	return names, nil
}

func loadTemplate() (*template.Template, error) {
	var content []byte
	var err error
	if *templateFile == "" {
		content = S2b(defaultTemplate)
	} else {
		content, err = os.ReadFile(*templateFile)
		if err != nil {
			return nil, fmt.Errorf("load template fail, err=%s", err.Error())
		}
	}
	var t *template.Template
	t, err = template.New("grafana").Parse(B2s(content))
	if err != nil {
		return nil, fmt.Errorf("template format error, err=%s", err.Error())
	}
	return t, nil
}

func main() {
	log.SetFlags(log.Lshortfile | log.LstdFlags)
	flag.Parse()
	err := config.Load(*configFile)
	if err != nil {
		log.Fatalln("load config file error:", err)
	}
	t, err := loadTemplate()
	if err != nil {
		log.Fatalln(err)
	}
	if len(*targetFile) == 0 {
		log.Fatalln("target file empty")
	}
	target, err := os.Create(*targetFile)
	if err != nil {
		log.Fatalln(err.Error())
	}
	defer target.Close()
	err = t.Execute(target, getParam())
	if err != nil {
		log.Fatalln(err.Error())
	}
	fmt.Println("ok")
}
