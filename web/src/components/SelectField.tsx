export type SelectOption<T extends string> = {
  value: T;
  label: string;
};

type SelectFieldProps<T extends string> = {
  label: string;
  value: T;
  options: SelectOption<T>[];
  onChange: (value: T) => void;
  className?: string;
};

export function SelectField<T extends string>({
  label,
  value,
  options,
  onChange,
  className
}: SelectFieldProps<T>) {
  return (
    <label className={`select-field ${className ?? ''}`}>
      <span>{label}</span>
      <select value={value} onChange={(event) => onChange(event.target.value as T)}>
        {options.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
    </label>
  );
}
