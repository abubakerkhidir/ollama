//go:build !darwin

package discover

// logAndPrepareMetalEnvs is a no-op on non-Darwin platforms.
// The real implementation lives in runner_egpu_darwin.go.
func logAndPrepareMetalEnvs() {}

// metalDeviceEnvs returns nil on non-Darwin platforms.
// The real implementation lives in runner_egpu_darwin.go.
func metalDeviceEnvs() map[string]string { return nil }
